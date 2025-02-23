#!/bin/bash

# Navigate to the ComfyUI directory
cd /comfyui

# Function to download a model if it doesn't exist
download_model() {
    local url=$1
    local output_path=$2
    if [ ! -f "$output_path" ]; then
        echo "Downloading $(basename $output_path)..."
        wget --retry-connrefused --tries=5 --timeout=30 -O "$output_path" "$url" || echo "Failed to download $(basename $output_path)"
    else
        echo "$(basename $output_path) already exists. Skipping download."
    fi
}

# Download models
download_model "https://civitai.com/api/download/models/354657" "models/checkpoints/DreamShaperXL.safetensors"
download_model "https://huggingface.co/stabilityai/sv3d/resolve/main/sv3d_u.safetensors" "models/checkpoints/sv3d_u.safetensors"
download_model "https://huggingface.co/stabilityai/control-lora/resolve/main/control-LoRAs-rank256/control-lora-canny-rank256.safetensors" "models/controlnet/control-lora-canny-rank256.safetensors"
download_model "https://huggingface.co/lllyasviel/fooocus_inpaint/resolve/main/inpaint_v26.fooocus.patch" "models/inpaint/inpaint_v26.fooocus.patch"
download_model "https://huggingface.co/lllyasviel/fooocus_inpaint/resolve/main/fooocus_inpaint_head.pth" "models/inpaint/fooocus_inpaint_head.pth"
download_model "https://github.com/Sanster/models/releases/download/add_mat/Places_512_FullData_G.pth" "models/inpaint/Places_512_FullData_G.pth"

# Start the ComfyUI server
python main.py
