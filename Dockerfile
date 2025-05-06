# Base image with CUDA support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

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

# Switch to non-root user
USER sduser

RUN pip3 install --no-cache-dir -r requirements.txt

# Start command
CMD ["python3", "./webui.py"]