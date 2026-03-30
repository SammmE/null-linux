#!/bin/bash
set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/../config.env"

BUSYBOX_TARBALL="$SRC_DIR/busybox-${BUSYBOX_VER}.tar.bz2"
BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VER}.tar.bz2"
BUSYBOX_BUILD_DIR="$SRC_DIR/busybox-${BUSYBOX_VER}"
BUSYBOX_MINIMAL_CONFIG="$SCRIPT_DIR/../../.agents/skills/musl-busybox-toolchain/references/busybox-minimal.config"

mkdir -p "$SRC_DIR" "$ROOTFS"

if [ ! -f "$BUSYBOX_TARBALL" ]; then
    wget -O "$BUSYBOX_TARBALL" "$BUSYBOX_URL"
fi

rm -rf "$BUSYBOX_BUILD_DIR"
tar -xjf "$BUSYBOX_TARBALL" -C "$SRC_DIR"

cd "$BUSYBOX_BUILD_DIR"

make distclean
if [ -f "$BUSYBOX_MINIMAL_CONFIG" ]; then
    cp "$BUSYBOX_MINIMAL_CONFIG" .config
else
    make defconfig
fi

set_config() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" .config; then
        sed -i "s|^${key}=.*|${key}=${value}|" .config
    elif grep -q "^# ${key} is not set$" .config; then
        sed -i "s|^# ${key} is not set$|${key}=${value}|" .config
    else
        printf '%s=%s\n' "$key" "$value" >> .config
    fi
}

set_config CONFIG_STATIC y
set_config CONFIG_ASH y
set_config CONFIG_FEATURE_INSTALLER y
set_config CONFIG_MODPROBE y
set_config CONFIG_FEATURE_MODPROBE_BLACKLIST y
set_config CONFIG_MKE2FS y
set_config CONFIG_SWITCH_ROOT y
set_config CONFIG_TC n

yes "" | make oldconfig

CC_BIN="gcc"
if command -v musl-gcc >/dev/null 2>&1; then
    CC_BIN="musl-gcc"
fi

CFLAGS="-Os -pipe -fdata-sections -ffunction-sections"
LDFLAGS="-static -Wl,--gc-sections -s"

make -j"$JOBS" \
    CC="$CC_BIN" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS"

make CONFIG_PREFIX="$ROOTFS" install

if [ -f "$ROOTFS/bin/busybox" ]; then
    strip --strip-all "$ROOTFS/bin/busybox"
fi
