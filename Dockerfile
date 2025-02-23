# Stage 1: Base image with common dependencies
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevent prompts during package installations
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1 
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git, and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1 \
    awscli \
    && ln -sf /usr/bin/python3.10 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install comfy-cli
RUN pip install comfy-cli

# Install ComfyUI
RUN yes | comfy --workspace /comfyui install --cuda-version 11.8 --nvidia --version 0.2.7

# Set working directory to ComfyUI
WORKDIR /comfyui

# Install custom nodes
RUN cd custom_nodes && \
    git clone https://github.com/shadowcz007/comfyui-mixlab-nodes && \
    git clone https://github.com/Acly/comfyui-tooling-nodes && \
    git clone https://github.com/WASasquatch/was-node-suite-comfyui && \
    git clone https://github.com/Acly/comfyui-inpaint-nodes && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite

# Create model directories
RUN mkdir -p models/checkpoints models/loras models/controlnet models/inpaint

# Copy extra model paths configuration
COPY src/extra_model_paths.yaml /comfyui/

# Return to root directory
WORKDIR /

# Add and set permissions for the start script
COPY src/start.sh /
RUN chmod +x /start.sh

# Set the start script as the container's entry point
CMD ["/start.sh"]
