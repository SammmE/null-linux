#!/bin/bash
set -e

echo "========================================"
echo "    Null Linux Build Orchestrator       "
echo "========================================"

# 1. Ensure the Docker image is built and up to date
echo "[1/2] Building Alpine build environment..."
docker build -t null-linux-builder .

# 2. Run the container and execute the components INSIDE it
echo "[2/2] Executing build scripts inside container..."
docker run --rm -it \
    -v "$PWD:/workspace" \
    null-linux-builder \
    /bin/bash -c "
        /workspace/scripts/components/setup-rootfs.sh &&
        /workspace/scripts/components/build-busybox.sh &&
        /workspace/scripts/components/build-kernel.sh &&
        /workspace/scripts/components/build-initramfs.sh &&
        /workspace/scripts/components/build-iso.sh
    "

echo "========================================"
echo "Build Complete! null-linux-amd64.iso is ready."
echo "========================================"