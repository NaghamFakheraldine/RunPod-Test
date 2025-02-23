#!/bin/bash

# Set up environment variables
export PYTHONUNBUFFERED=1

# Log file setup
LOG_FILE="/comfyui/comfyui.log"
echo "Starting ComfyUI..." > $LOG_FILE

# Print environment variables for debugging
echo "Environment variables:" >> $LOG_FILE
env >> $LOG_FILE

# Check and ensure required directories exist
REQUIRED_DIRS=("models/checkpoints" "models/loras" "models/controlnet" "models/inpaint")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating missing directory: $dir" >> $LOG_FILE
        mkdir -p "$dir"
    fi
done

# Update models from AWS S3 if credentials are provided
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS credentials provided, checking for model updates..." >> $LOG_FILE
    aws s3 sync s3://loras-bucket/Elie_Saab/V2/ /comfyui/models/loras/ || \
    echo "Failed to sync models from S3. Continuing without updates..." >> $LOG_FILE
else
    echo "No AWS credentials provided, skipping model updates from S3." >> $LOG_FILE
fi

# Start ComfyUI server
echo "Launching ComfyUI server..." >> $LOG_FILE
python3 main.py --listen --workspace /comfyui >> $LOG_FILE 2>&1
