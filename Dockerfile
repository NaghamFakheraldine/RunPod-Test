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
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

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

# Download models with retries and error handling
RUN cd models/checkpoints && \
    wget --retry-connrefused --tries=5 --timeout=30 \
    -O "DreamShaperXL.safetensors" "https://civitai.com/api/download/models/354657" || exit 0

# Use ARG for Hugging Face token
ARG HF_TOKEN
RUN cd models/checkpoints && \
    if [ ! -z "$HF_TOKEN" ]; then \
        wget --retry-connrefused --tries=5 --timeout=30 \
        --header="Authorization: Bearer ${HF_TOKEN}" \
        -O "sv3d_u.safetensors" \
        "https://huggingface.co/stabilityai/sv3d/resolve/main/sv3d_u.safetensors" || exit 0; \
    fi

RUN cd models/controlnet && \
    wget --retry-connrefused --tries=5 --timeout=30 \
    --header="Authorization: Bearer ${HF_TOKEN}" \
    -O "control-lora-canny-rank256.safetensors" \
    "https://huggingface.co/stabilityai/control-lora/resolve/main/control-LoRAs-rank256/control-lora-canny-rank256.safetensors" || exit 0

RUN cd models/inpaint && \
    wget --retry-connrefused --tries=5 --timeout=30 \
    --header="Authorization: Bearer ${HF_TOKEN}" \
    -O "inpaint_v26.fooocus.patch" \
    "https://huggingface.co/lllyasviel/fooocus_inpaint/resolve/main/inpaint_v26.fooocus.patch" || exit 0

RUN cd models/inpaint && \
    wget --retry-connrefused --tries=5 --timeout=30 \
    --header="Authorization: Bearer ${HF_TOKEN}" \
    -O "fooocus_inpaint_head.pth" \
    "https://huggingface.co/lllyasviel/fooocus_inpaint/resolve/main/fooocus_inpaint_head.pth" || exit 0

RUN cd models/inpaint && \
    wget -O "Places_512_FullData_G.pth" https://github.com/Sanster/models/releases/download/add_mat/Places_512_FullData_G.pth

# Install runpod and requests
RUN pip install runpod requests

# Copy extra model paths configuration
COPY src/extra_model_paths.yaml /comfyui/

# Return to root directory
WORKDIR /

# Add and set permissions for scripts
COPY src/start.sh /start.sh
RUN chmod +x /start.sh

# Use ARG for AWS credentials
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_DEFAULT_REGION

# Set AWS credentials as environment variables
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ENV AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

# Download models from S3 if credentials are provided
WORKDIR /comfyui
RUN cd models/loras && \
    if [ ! -z "$AWS_ACCESS_KEY_ID" ] && [ ! -z "$AWS_SECRET_ACCESS_KEY" ]; then \
        aws s3 cp s3://loras-bucket/Elie_Saab/V2/ElieSaabLoraV2.safetensors . || \
        echo "Failed to download from S3, continuing build..."; \
    else \
        echo "AWS credentials not provided, skipping S3 download..."; \
    fi

# Set the start script as the container's entry point
CMD ["/start.sh"]
