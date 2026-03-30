#!/bin/bash
set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/../config.env"

LIMINE_REPO_URL="https://github.com/limine-bootloader/limine.git"
LIMINE_SRC_DIR="$SRC_DIR/limine"
LIMINE_BUILD_DIR="$SRC_DIR/limine-build"
LIMINE_BIN_DIR="$LIMINE_BUILD_DIR/bin"
OUT_ISO="/workspace/null-linux-amd64.iso"
KERNEL_IMAGE="$ROOTFS/boot/vmlinuz"
INITRAMFS_IMAGE="$ROOTFS/boot/initramfs.cpio.gz"

mkdir -p "$SRC_DIR" "$ROOTFS/boot"

if [ ! -d "$LIMINE_SRC_DIR/.git" ]; then
    rm -rf "$LIMINE_SRC_DIR"
    git clone "$LIMINE_REPO_URL" "$LIMINE_SRC_DIR"
fi

git -C "$LIMINE_SRC_DIR" fetch --tags --force
git -C "$LIMINE_SRC_DIR" -c advice.detachedHead=false checkout "v${LIMINE_VER}"

rm -rf "$LIMINE_BUILD_DIR"
"$LIMINE_SRC_DIR/bootstrap"
mkdir -p "$LIMINE_BUILD_DIR"
(
    cd "$LIMINE_BUILD_DIR"
    CC_FOR_TARGET=gcc \
    LD_FOR_TARGET=ld \
    OBJCOPY_FOR_TARGET=objcopy \
    OBJDUMP_FOR_TARGET=objdump \
    READELF_FOR_TARGET=readelf \
    "$LIMINE_SRC_DIR/configure" \
        --enable-bios \
        --enable-bios-cd \
        --enable-uefi-x86-64 \
        --enable-uefi-cd
    make -j"$JOBS"
)

for required_file in \
    "$KERNEL_IMAGE" \
    "$INITRAMFS_IMAGE" \
    "$LIMINE_BIN_DIR/limine" \
    "$LIMINE_BIN_DIR/limine-bios.sys" \
    "$LIMINE_BIN_DIR/limine-bios-cd.bin" \
    "$LIMINE_BIN_DIR/limine-uefi-cd.bin"; do
    if [ ! -f "$required_file" ]; then
        echo "Required file not found: $required_file" >&2
        exit 1
    fi
done

mkdir -p "$ROOTFS/EFI/BOOT"

cat > "$ROOTFS/boot/limine.conf" <<'EOF'
TIMEOUT=3

:Null Linux
PROTOCOL=linux
KERNEL_PATH=boot:///boot/vmlinuz
MODULE_PATH=boot:///boot/initramfs.cpio.gz
CMDLINE=console=tty0 console=ttyS0
EOF

cp "$LIMINE_BIN_DIR/limine-bios.sys" "$ROOTFS/boot/"
cp "$LIMINE_BIN_DIR/limine-bios-cd.bin" "$ROOTFS/boot/"
cp "$LIMINE_BIN_DIR/limine-uefi-cd.bin" "$ROOTFS/boot/"

if [ -f "$LIMINE_BIN_DIR/BOOTX64.EFI" ]; then
    cp "$LIMINE_BIN_DIR/BOOTX64.EFI" "$ROOTFS/EFI/BOOT/"
fi

if [ -f "$LIMINE_BIN_DIR/BOOTIA32.EFI" ]; then
    cp "$LIMINE_BIN_DIR/BOOTIA32.EFI" "$ROOTFS/EFI/BOOT/"
fi

xorriso -as mkisofs \
    -b boot/limine-bios-cd.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --efi-boot boot/limine-uefi-cd.bin \
    -efi-boot-part \
    --efi-boot-image \
    --protective-msdos-label \
    "$ROOTFS" \
    -o "$OUT_ISO"

"$LIMINE_BIN_DIR/limine" bios-install "$OUT_ISO"
