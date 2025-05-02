ARG PYTHON_VERSION=3.10
ARG CUDA_VERSION=11.8.0
ARG CUDNN_VERSION=8
ARG BUILD_TYPE=prod

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-runtime-ubuntu22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    wget \
    python3 \
    python3-venv \
    python3-pip \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git

WORKDIR /app/stable-diffusion-webui

# Clone Stable Diffusion repository
RUN mkdir -p repositories && \
    cd repositories && \
    git clone https://github.com/Stability-AI/stablediffusion.git stable-diffusion-stability-ai

# Create necessary directories
RUN mkdir -p models/Stable-diffusion && \
    mkdir -p models/VAE && \
    mkdir -p embeddings && \
    mkdir -p outputs && \
    mkdir -p extensions

# Download a base model (you might want to change this to your preferred model)
RUN wget -q https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors -O models/Stable-diffusion/v1-5-pruned.safetensors

# Install Python dependencies
RUN pip${PYTHON_VERSION} install --no-cache-dir -r requirements.txt

# Expose the port
EXPOSE 7860

# Start the web UI
CMD ["python3", "webui.py", "--listen", "--port", "7860"]

# Development stage
FROM base AS dev

RUN apt-get update && apt-get install -y \
    vim \
    curl \
    && rm -rf /var/lib/apt/lists/* 