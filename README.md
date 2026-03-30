# Null Linux

`Null Linux` is a small scripted Linux build that produces a root filesystem,
kernel, initramfs, and bootable ISO from a reproducible Docker build
environment.

## Repository Layout

- `Dockerfile`: build environment definition
- `scripts/`: build orchestration and component scripts
- `overlay/`: tracked static files copied into the generated rootfs
- `.gitignore`: ignores downloads and generated artifacts

Generated outputs such as `src/`, `build/`, `rootfs/`, `initramfs-staging/`,
and `*.iso` are intentionally not tracked.

## Build

Build the container image:

```bash
docker build -t null-linux-builder .
```

Run the full build:

```bash
docker run --rm -it -v "$PWD":/workspace -w /workspace null-linux-builder \
  bash -lc "./scripts/build-all.sh"
```

The main outputs are:

- `rootfs/boot/vmlinuz`
- `rootfs/boot/initramfs.cpio.gz`
- `null-linux-amd64.iso`

## Boot And Install

Null Linux is designed to boot as a live ISO first, then install itself onto a
disk from inside the running system.

Build the project:

```bash
docker build -t null-linux-builder .
bash ./scripts/build-all.sh
```

Create a virtual hard disk for installation:

```bash
qemu-img create -f qcow2 null-hdd.qcow2 4G
```

Boot the live ISO with that disk attached:

```bash
qemu-system-x86_64 \
  -m 1024 \
  -cdrom null-linux-amd64.iso \
  -drive file=null-hdd.qcow2,format=qcow2,if=virtio \
  -boot d \
  -serial mon:stdio
```

Inside the live environment, run the installer:

```sh
null-install
poweroff
```

After shutdown, boot from the installed disk instead of the ISO:

```bash
qemu-system-x86_64 \
  -m 1024 \
  -drive file=null-hdd.qcow2,format=qcow2,if=virtio \
  -boot c \
  -serial mon:stdio
```

`-serial mon:stdio` is recommended so kernel and initramfs logs are visible in
your terminal during boot.

## Installation Flow

1. Boot the `null-linux-amd64.iso` image as a live environment.
2. The bootloader loads the kernel and initramfs into RAM.
3. The live system runs from the ISO in read-only mode.
4. Run `null-install` to partition, format, and populate the target disk.
5. Reboot without the ISO attached to boot the persistent installation.

## QEMU Disk Naming Note

The installer currently targets `/dev/sda` inside
[`overlay/usr/sbin/null-install`](./overlay/usr/sbin/null-install). In QEMU, a
disk attached with `if=virtio` often appears as `/dev/vda` instead. If the
installer does not find `/dev/sda`, either attach the disk as a SATA/IDE-style
device or update the installer to support `/dev/vda`.

## Overlay

Files under `overlay/` are copied directly into the generated rootfs near the
end of `scripts/components/setup-rootfs.sh`. This keeps static system files in
Git instead of embedding large `echo` blocks inside build scripts.
