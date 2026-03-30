#!/bin/bash
set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/../config.env"

MODULE_NAMES="nvme ahci sd_mod virtio_blk ext4 fat vfat nls_cp437 nls_iso8859_1"
KERNEL_MODULES_ROOT="$ROOTFS/lib/modules"
OUT_INITRAMFS="$ROOTFS/boot/initramfs.cpio.gz"
KERNEL_RELEASE=""

require_kmod_depmod() {
    local depmod_bin

    depmod_bin="${DEPMOD:-$(command -v depmod || true)}"
    if [ -z "$depmod_bin" ]; then
        echo "depmod not found. Install the kmod package in the build environment." >&2
        exit 1
    fi

    if "$depmod_bin" --help 2>&1 | grep -q "BusyBox"; then
        echo "BusyBox depmod is not compatible with this initramfs module indexing step." >&2
        echo "Install the kmod package so /usr/sbin/depmod is available." >&2
        exit 1
    fi

    printf '%s\n' "$depmod_bin"
}

DEPMOD_BIN="$(require_kmod_depmod)"

if [ ! -d "$KERNEL_MODULES_ROOT" ]; then
    echo "Kernel modules directory not found: $KERNEL_MODULES_ROOT" >&2
    exit 1
fi

KERNEL_RELEASE="$(find "$KERNEL_MODULES_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | head -n 1)"
KERNEL_RELEASE="${KERNEL_RELEASE##*/}"

if [ -z "$KERNEL_RELEASE" ]; then
    echo "No installed kernel module tree found under $KERNEL_MODULES_ROOT" >&2
    exit 1
fi

rm -rf "$INITRAMFS_STAGING"
mkdir -p \
    "$INITRAMFS_STAGING/bin" \
    "$INITRAMFS_STAGING/dev" \
    "$INITRAMFS_STAGING/etc" \
    "$INITRAMFS_STAGING/lib" \
    "$INITRAMFS_STAGING/mnt/root" \
    "$INITRAMFS_STAGING/proc" \
    "$INITRAMFS_STAGING/run" \
    "$INITRAMFS_STAGING/sys" \
    "$INITRAMFS_STAGING/lib/modules/$KERNEL_RELEASE" \
    "$ROOTFS/boot"

cp "$ROOTFS/bin/busybox" "$INITRAMFS_STAGING/bin/busybox"
(
    cd "$INITRAMFS_STAGING/bin"
    ./busybox --install -s .

    # BusyBox may emit absolute symlinks based on argv[0]; rewrite them so the
    # initramfs stays self-contained after it is unpacked at /.
    find . -maxdepth 1 -type l ! -name busybox | while IFS= read -r applet; do
        ln -snf busybox "$applet"
    done
)

for module in $MODULE_NAMES; do
    while IFS= read -r module_path; do
        rel_path="${module_path#$KERNEL_MODULES_ROOT/$KERNEL_RELEASE/}"
        mkdir -p "$INITRAMFS_STAGING/lib/modules/$KERNEL_RELEASE/$(dirname "$rel_path")"
        cp "$module_path" "$INITRAMFS_STAGING/lib/modules/$KERNEL_RELEASE/$rel_path"
    done < <(
        find "$KERNEL_MODULES_ROOT/$KERNEL_RELEASE" -type f \
            \( -name "$module.ko" -o -name "$module.ko.gz" -o -name "$module.ko.xz" -o -name "$module.ko.zst" \)
    )
done

for metadata_file in modules.order modules.builtin modules.builtin.modinfo; do
    if [ -f "$KERNEL_MODULES_ROOT/$KERNEL_RELEASE/$metadata_file" ]; then
        cp \
            "$KERNEL_MODULES_ROOT/$KERNEL_RELEASE/$metadata_file" \
            "$INITRAMFS_STAGING/lib/modules/$KERNEL_RELEASE/$metadata_file"
    fi
done

"$DEPMOD_BIN" -b "$INITRAMFS_STAGING" "$KERNEL_RELEASE"

cat > "$INITRAMFS_STAGING/init" <<'EOF'
#!/bin/sh
# 1. Mount essential virtual filesystems
mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys

# 2. Populate /dev using BusyBox mdev
if [ -w /proc/sys/kernel/hotplug ]; then
  echo /bin/mdev > /proc/sys/kernel/hotplug
fi
mdev -s

# 3. Parse kernel command line for the "root=" parameter
read -r cmdline < /proc/cmdline
for param in $cmdline; do
  case $param in
    root=*) ROOT_DEV=${param#root=} ;;
  esac
done

# 4. Load required modules (Example: ext4)
# modprobe ext4

# 5. Wait for the root device to appear
while [ ! -b "$ROOT_DEV" ]; do
  echo "Waiting for $ROOT_DEV..."
  sleep 1
done

# 6. Mount the real root filesystem
mount -o ro "$ROOT_DEV" /mnt/root

# 7. Clean up and switch root
exec switch_root /mnt/root /sbin/init
EOF

chmod +x "$INITRAMFS_STAGING/init"

(
    cd "$INITRAMFS_STAGING"
    find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "$OUT_INITRAMFS"
)
