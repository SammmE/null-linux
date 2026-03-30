#!/bin/bash
set -e

echo "Starting Null Linux Build Process..."

ROOTFS="/workspace/rootfs"

echo "Creating root filesystem skeleton..."
mkdir -p $ROOTFS/{bin,sbin,etc,dev,proc,sys,tmp,usr,var,mnt,run}
mkdir -p $ROOTFS/usr/{bin,sbin,lib}
mkdir -p $ROOTFS/var/{log,run}

# Ensure standard permissions
chmod 1777 $ROOTFS/tmp
chmod 0755 $ROOTFS/var

echo "Rootfs skeleton created successfully!"