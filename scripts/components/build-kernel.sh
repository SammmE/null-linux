#!/bin/bash
set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/../config.env"

KERNEL_TARBALL="$SRC_DIR/linux-${KERNEL_VER}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VER}.tar.xz"
KERNEL_SRC_DIR="$SRC_DIR/linux-${KERNEL_VER}"
KERNEL_BUILD_DIR="/workspace/build/kernel"

require_kmod_depmod() {
    local depmod_bin

    depmod_bin="${DEPMOD:-$(command -v depmod || true)}"
    if [ -z "$depmod_bin" ]; then
        echo "depmod not found. Install the kmod package in the build environment." >&2
        exit 1
    fi

    if "$depmod_bin" --help 2>&1 | grep -q "BusyBox"; then
        echo "BusyBox depmod is not compatible with kernel modules_install in this build." >&2
        echo "Install the kmod package so /usr/sbin/depmod is available." >&2
        exit 1
    fi

    printf '%s\n' "$depmod_bin"
}

DEPMOD_BIN="$(require_kmod_depmod)"

mkdir -p "$SRC_DIR" "$ROOTFS/boot" "$ROOTFS/lib/modules" "$KERNEL_BUILD_DIR"

if [ ! -f "$KERNEL_TARBALL" ]; then
    if command -v curl >/dev/null 2>&1; then
        curl -L "$KERNEL_URL" -o "$KERNEL_TARBALL"
    else
        wget -O "$KERNEL_TARBALL" "$KERNEL_URL"
    fi
fi

rm -rf "$KERNEL_SRC_DIR" "$KERNEL_BUILD_DIR"
mkdir -p "$KERNEL_BUILD_DIR"
tar -xJf "$KERNEL_TARBALL" -C "$SRC_DIR"

cd "$KERNEL_SRC_DIR"

make O="$KERNEL_BUILD_DIR" ARCH=x86_64 defconfig
make O="$KERNEL_BUILD_DIR" ARCH=x86_64 -j"$JOBS" bzImage modules

cp "$KERNEL_BUILD_DIR/arch/x86/boot/bzImage" "$ROOTFS/boot/vmlinuz"

make O="$KERNEL_BUILD_DIR" \
    ARCH=x86_64 \
    DEPMOD="$DEPMOD_BIN" \
    INSTALL_MOD_PATH="$ROOTFS" \
    modules_install
