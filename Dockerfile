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

# Create and set permissions for Python package directories
RUN mkdir -p /home/sduser/.local/lib/python3.10/site-packages && \
    chown -R sduser:sduser /home/sduser/.local

# Switch to non-root user
USER sduser

# Install PyTorch first
RUN pip3 install --no-cache-dir torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy taming modules to stable-diffusion-stability-ai
RUN mkdir -p /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai/taming && \
    cp -r /app/stable-diffusion-webui/repositories/taming-transformers/taming/* /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai/taming/

# Install stable-diffusion
WORKDIR /app/stable-diffusion-webui/repositories/stable-diffusion-stability-ai
RUN pip3 install --no-cache-dir .

# Install k-diffusion
WORKDIR /app/stable-diffusion-webui/repositories/k-diffusion
RUN pip3 install --no-cache-dir .

# Install SGM and its dependencies
WORKDIR /app/stable-diffusion-webui/repositories/generative-models/sgm
RUN pip3 install --no-cache-dir hatchling && \
    pip3 install --no-cache-dir . && \
    pip3 install --no-cache-dir omegaconf pytorch-lightning einops

# Install stablediffusion
WORKDIR /app/stable-diffusion-webui/repositories/stablediffusion
RUN pip3 install --no-cache-dir .

# Return to main directory
WORKDIR /app/stable-diffusion-webui

# Start command
CMD ["python3", "./webui.py"]