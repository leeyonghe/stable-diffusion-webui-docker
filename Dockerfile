ARG PYTHON_VERSION=3.10
ARG CUDA_VERSION=11.8.0
ARG CUDNN_VERSION=8
ARG BUILD_TYPE=prod

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-runtime-ubuntu22.04 AS base

# 환경 변수 설정
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 시스템 의존성 설치
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

# 작업 디렉토리 설정
WORKDIR /app

# 저장소 클론
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git

WORKDIR /app/stable-diffusion-webui

# Stable Diffusion 저장소 클론
RUN mkdir -p repositories && \
    cd repositories && \
    git clone https://github.com/CompVis/stable-diffusion.git stable-diffusion-stability-ai && \
    git clone https://github.com/Stability-AI/generative-models.git sgm && \
    git clone https://github.com/salesforce/BLIP.git && \
    git clone https://github.com/crowsonkb/k-diffusion.git

# Install required dependencies
RUN pip${PYTHON_VERSION} install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip${PYTHON_VERSION} install --no-cache-dir einops k-diffusion safetensors transformers && \
    cd repositories/sgm && pip${PYTHON_VERSION} install -e . && \
    cd ../BLIP && pip${PYTHON_VERSION} install -e . && \
    cd ../k-diffusion && pip${PYTHON_VERSION} install -e .

# Note: SGM package installation is skipped as it requires authentication
# Please install it manually after building the container

# 필요한 디렉토리 생성
RUN mkdir -p models/Stable-diffusion && \
    mkdir -p models/VAE && \
    mkdir -p embeddings && \
    mkdir -p outputs && \
    mkdir -p extensions

# 기본 모델 다운로드 (원하는 모델로 변경 가능)
RUN wget -q https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned.safetensors -O models/Stable-diffusion/v1-5-pruned.safetensors

# Python 의존성 설치
RUN pip${PYTHON_VERSION} install --no-cache-dir -r requirements.txt && \
    pip${PYTHON_VERSION} install --no-cache-dir ftfy regex tqdm && \
    pip${PYTHON_VERSION} install --no-cache-dir git+https://github.com/openai/CLIP.git && \
    pip${PYTHON_VERSION} install --no-cache-dir fastapi uvicorn python-multipart

# 포트 노출
EXPOSE 7860

# 웹 UI 시작
CMD ["python3", "webui.py", "--listen", "--port", "7860"]

# 개발 환경 스테이지
FROM base AS dev

RUN apt-get update && apt-get install -y \
    vim \
    curl \
    && rm -rf /var/lib/apt/lists/* 