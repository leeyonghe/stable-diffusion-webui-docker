group "default" {
  targets = ["stable-diffusion-webui"]
}

variable "TAG" {
  default = "latest"
}

target "stable-diffusion-webui" {
  dockerfile = "Dockerfile"
  context = "."
  tags = ["stable-diffusion-webui:${TAG}"]
  platforms = ["linux/amd64"]
  
  args = {
    PYTHON_VERSION = "3.10"
    CUDA_VERSION = "11.8.0"
    CUDNN_VERSION = "8"
  }

  cache-from = [
    "type=registry,ref=stable-diffusion-webui:cache"
  ]
  cache-to = [
    "type=registry,ref=stable-diffusion-webui:cache,mode=max"
  ]
}

target "stable-diffusion-webui-dev" {
  inherits = ["stable-diffusion-webui"]
  target = "dev"
  tags = ["stable-diffusion-webui:dev"]
  
  args = {
    BUILD_TYPE = "dev"
  }
} 