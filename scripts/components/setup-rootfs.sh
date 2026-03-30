#!/bin/bash
set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/../config.env"

mkdir -p "$SRC_DIR"

mkdir -p \
    "$ROOTFS/bin" \
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
    "$ROOTFS/usr/sbin" \
    "$ROOTFS/var" \
    "$ROOTFS/var/log" \
    "$ROOTFS/mnt" \
    "$ROOTFS/root"

chmod 0755 "$ROOTFS"
chmod 0755 "$ROOTFS/bin" "$ROOTFS/sbin" "$ROOTFS/etc" "$ROOTFS/etc/init.d" "$ROOTFS/etc/runit"
chmod 0755 "$ROOTFS/etc/runit/runsvdir/default" "$ROOTFS/etc/sv"
chmod 0755 "$ROOTFS/dev" "$ROOTFS/dev/pts" "$ROOTFS/run" "$ROOTFS/usr" "$ROOTFS/usr/bin" "$ROOTFS/usr/sbin"
chmod 1777 "$ROOTFS/dev/shm"
chmod 0755 "$ROOTFS/var" "$ROOTFS/var/log" "$ROOTFS/mnt"
chmod 0555 "$ROOTFS/proc" "$ROOTFS/sys"
chmod 1777 "$ROOTFS/tmp"
chmod 0700 "$ROOTFS/root"

ln -sfn /run "$ROOTFS/var/run"
ln -sfn /proc/mounts "$ROOTFS/etc/mtab"

if [ -d /workspace/overlay ]; then
    # Copy tracked static files into the generated rootfs.
    cp -a /workspace/overlay/. "$ROOTFS/"
fi
