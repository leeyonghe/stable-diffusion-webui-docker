# Base image with CUDA support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/stable-diffusion-webui/repositories/BLIP

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

# Create and set working directory
WORKDIR /app

# Clone the main repository
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git

# Set working directory
WORKDIR /app/stable-diffusion-webui

# Create repositories directory
RUN mkdir -p repositories

# Clone required repositories
WORKDIR /app/stable-diffusion-webui/repositories
RUN git clone https://github.com/CompVis/stable-diffusion.git stable-diffusion-stability-ai && \
    git clone https://github.com/Stability-AI/generative-models.git sgm && \
    git clone https://github.com/salesforce/BLIP.git

# Install PyTorch with CUDA support
WORKDIR /app/stable-diffusion-webui
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Install core dependencies
RUN pip3 install --no-cache-dir \
    einops \
    k-diffusion \
    safetensors \
    transformers==4.30.2 \
    setuptools-rust \
    tokenizers==0.13.3

# Install SGM
WORKDIR /app/stable-diffusion-webui/repositories/sgm
RUN pip3 install -e .

# Install BLIP dependencies
WORKDIR /app/stable-diffusion-webui/repositories/BLIP
RUN pip3 install --no-cache-dir \
    timm==0.4.12 \
    transformers==4.15.0 \
    fairscale==0.4.4 \
    pycocoevalcap

# Set working directory back to main
WORKDIR /app/stable-diffusion-webui

# Create necessary directories
RUN mkdir -p models/Stable-diffusion && \
    mkdir -p models/VAE && \
    mkdir -p embeddings && \
    mkdir -p outputs && \
    mkdir -p extensions

# Download default model
RUN wget -q https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors -O models/Stable-diffusion/v1-5-pruned.safetensors

# Install remaining requirements
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 7860

# Start command
CMD ["python3", "webui.py", "--listen", "--port", "7860"]