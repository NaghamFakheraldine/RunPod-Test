#!/usr/bin/env bash

set -e

SNAPSHOT_FILE=$(ls /*snapshot*.json 2>/dev/null | head -n 1)

if [ -z "$SNAPSHOT_FILE" ]; then
    echo "weaver-ai-comfy: No snapshot file found. Exiting..."
    exit 0
fi

echo "weaver-ai-comfy: restoring snapshot: $SNAPSHOT_FILE"

# Check if comfy command is available
if ! command -v comfy &> /dev/null; then
    echo "weaver-ai-comfy: comfy command not found. Please install comfy."
    exit 1
fi

comfy --workspace /comfyui node restore-snapshot "$SNAPSHOT_FILE" --pip-non-url

echo "runpod-worker-comfy: restored snapshot file: $SNAPSHOT_FILE"