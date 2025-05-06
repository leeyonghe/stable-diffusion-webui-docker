# Base image with CUDA support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/stable-diffusion-webui:/app/stable-diffusion-webui/repositories/BLIP:/app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai:/app/stable-diffusion-webui/repositories/taming-transformers:/app/stable-diffusion-webui/repositories/sgm:/app/stable-diffusion-webui/repositories/stablediffusion

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    python3 \
    python3-venv \
    python3-pip \
    libgl1 \
    libglib2.0-0 \
    curl \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo

# Set up Python environment
RUN python3 -m pip install --upgrade pip setuptools wheel

# Set working directory
WORKDIR /app/stable-diffusion-webui

# Create repositories directory
RUN mkdir -p repositories

# Copy the application files
COPY . .

# Install core dependencies
RUN pip3 install --no-cache-dir \
    einops \
    safetensors \
    transformers==4.30.2 \
    setuptools-rust \
    tokenizers==0.13.3 \
    ftfy \
    regex \
    tqdm \
    open_clip_torch \
    git+https://github.com/openai/CLIP.git \
    pytorch_lightning==1.9.4 \
    timm==0.4.12 \
    fairscale==0.4.4 \
    pycocoevalcap

# Install PyTorch with CUDA support first
RUN pip3 install --no-cache-dir torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu118

# Install xformers with CUDA support
RUN pip3 install --no-cache-dir xformers==0.0.22.post7 --index-url https://download.pytorch.org/whl/cu118

# Install stable-diffusion
WORKDIR /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai
RUN pip3 install -e .

# Install k-diffusion
WORKDIR /app/stable-diffusion-webui/repositories/k-diffusion
RUN pip3 install -e .

# Install taming-transformers
WORKDIR /app/stable-diffusion-webui/repositories/taming-transformers
RUN pip3 install -e .

# Install SGM
WORKDIR /app/stable-diffusion-webui/repositories/generative-models/sgm
RUN pip3 install -e .

# Install stablediffusion
WORKDIR /app/stable-diffusion-webui/repositories/stablediffusion
RUN pip3 install -e .

# Install BLIP dependencies
WORKDIR /app/stable-diffusion-webui/repositories/BLIP

# Set working directory back to main
WORKDIR /app/stable-diffusion-webui

# Install remaining requirements
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 7860

# Start command
CMD ["python3", "webui.py", "--listen", "--port", "7860"]