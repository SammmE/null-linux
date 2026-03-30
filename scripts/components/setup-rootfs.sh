#!/bin/bash
set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/../config.env"

mkdir -p "$SRC_DIR"

mkdir -p \
    "$ROOTFS/bin" \
    "$ROOTFS/lib" \
    "$ROOTFS/sbin" \
    "$ROOTFS/etc" \
    "$ROOTFS/etc/init.d" \
    "$ROOTFS/etc/runit" \
    "$ROOTFS/etc/runit/runsvdir/default" \
    "$ROOTFS/etc/sv" \
    "$ROOTFS/dev" \
    "$ROOTFS/dev/pts" \
    "$ROOTFS/dev/shm" \
    "$ROOTFS/proc" \
    "$ROOTFS/sys" \
    "$ROOTFS/run" \
    "$ROOTFS/tmp" \
    "$ROOTFS/usr" \
    "$ROOTFS/usr/bin" \
    "$ROOTFS/usr/lib" \
    "$ROOTFS/usr/sbin" \
    "$ROOTFS/var" \
    "$ROOTFS/var/log" \
    "$ROOTFS/mnt" \
    "$ROOTFS/root"

chmod 0755 "$ROOTFS"
chmod 0755 "$ROOTFS/bin" "$ROOTFS/lib" "$ROOTFS/sbin" "$ROOTFS/etc" "$ROOTFS/etc/init.d" "$ROOTFS/etc/runit"
chmod 0755 "$ROOTFS/etc/runit/runsvdir/default" "$ROOTFS/etc/sv"
chmod 0755 "$ROOTFS/dev" "$ROOTFS/dev/pts" "$ROOTFS/run" "$ROOTFS/usr" "$ROOTFS/usr/bin" "$ROOTFS/usr/lib" "$ROOTFS/usr/sbin"
chmod 1777 "$ROOTFS/dev/shm"
chmod 0755 "$ROOTFS/var" "$ROOTFS/var/log" "$ROOTFS/mnt"
chmod 0555 "$ROOTFS/proc" "$ROOTFS/sys"
chmod 1777 "$ROOTFS/tmp"
chmod 0700 "$ROOTFS/root"

ln -sfn /run "$ROOTFS/var/run"
ln -sfn /proc/mounts "$ROOTFS/etc/mtab"

cp -a /sbin/mkfs.ext4 "$ROOTFS/sbin/"
cp -a /lib/ld-musl-x86_64.so.1 "$ROOTFS/lib/"
cp -a \
    /usr/lib/libext2fs.so.2 \
    /usr/lib/libcom_err.so.2 \
    /usr/lib/libblkid.so.1 \
    /usr/lib/libuuid.so.1 \
    /usr/lib/libe2p.so.2 \
    /usr/lib/libeconf.so.0 \
    "$ROOTFS/usr/lib/"

if [ -d /workspace/overlay ]; then
    # Copy tracked static files into the generated rootfs.
    cp -a /workspace/overlay/. "$ROOTFS/"
fi
