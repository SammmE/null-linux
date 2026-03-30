#!/bin/bash
set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/config.env"

"$SCRIPT_DIR/components/setup-rootfs.sh"
"$SCRIPT_DIR/components/build-busybox.sh"
"$SCRIPT_DIR/components/build-kernel.sh"
"$SCRIPT_DIR/components/build-initramfs.sh"
"$SCRIPT_DIR/components/build-iso.sh"
