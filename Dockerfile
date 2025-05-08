# Base image with CUDA support
FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    wget \
    python3 \
    python3-venv \
    python3-pip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash sduser && \
    mkdir -p /app && \
    chown -R sduser:sduser /app

COPY . /app/stable-diffusion-webui
RUN chown -R sduser:sduser /app/stable-diffusion-webui

WORKDIR /app/stable-diffusion-webui

# Make webui.sh executable
RUN chmod +x webui.sh

# Set up Python environment
ENV PYTHONPATH=/app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai:/home/sduser/.local/lib/python3.10/site-packages
ENV PATH=/home/sduser/.local/bin:$PATH
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860
ENV HF_HUB_DISABLE_RESUME_DOWNLOAD=1
ENV HF_HUB_DISABLE_PROGRESS_BARS=1
ENV GRADIO_SERVER_SHARE=true

# Create and set permissions for Python package directories
RUN mkdir -p /home/sduser/.local/lib/python3.10/site-packages && \
    chown -R sduser:sduser /home/sduser/.local

# Switch to non-root user
USER sduser

# Install PyTorch first
RUN pip3 install --no-cache-dir torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu121

# Install Python dependencies with specific versions
RUN pip3 install --no-cache-dir -r requirements.txt && \
    pip3 install --no-cache-dir "pydantic<2.0.0" "gradio==3.41.2" "huggingface-hub>=0.19.4" "xformers"

# Clean up any existing repositories directory
RUN rm -rf /app/stable-diffusion-webui/repositories/*

# Clone and install stable-diffusion-stability-ai
RUN git clone https://github.com/Stability-AI/stablediffusion.git /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai && \
    cd /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai && \
    pip3 install --no-cache-dir .

# Install midas and other required dependencies
RUN pip3 install --no-cache-dir timm opencv-python-headless

# Clone and copy taming modules
RUN git clone https://github.com/CompVis/taming-transformers.git /app/stable-diffusion-webui/repositories/taming-transformers && \
    mkdir -p /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai/taming && \
    cp -r /app/stable-diffusion-webui/repositories/taming-transformers/taming/* /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai/taming/

# Install k-diffusion
RUN git clone https://github.com/crowsonkb/k-diffusion.git /app/stable-diffusion-webui/repositories/k-diffusion && \
    cd /app/stable-diffusion-webui/repositories/k-diffusion && \
    pip3 install --no-cache-dir .

# Install SGM and its dependencies
RUN git clone https://github.com/Stability-AI/generative-models.git /app/stable-diffusion-webui/repositories/generative-models && \
    pip3 install --no-cache-dir omegaconf pytorch-lightning einops && \
    cd /app/stable-diffusion-webui/repositories/generative-models && \
    pip3 install --no-cache-dir -e .

# Clone stablediffusion repository and assets
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git /app/stable-diffusion-webui/repositories/stablediffusion && \
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets.git /app/stable-diffusion-webui/repositories/stable-diffusion-webui-assets

# Clone BLIP repository
RUN git clone https://github.com/salesforce/BLIP.git /app/stable-diffusion-webui/repositories/BLIP

# Return to main directory
WORKDIR /app/stable-diffusion-webui

# Start command
CMD ["python3", "./webui.py", "--no-half", "--no-half-vae", "--disable-nan-check"]