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

## Overlay

Files under `overlay/` are copied directly into the generated rootfs near the
end of `scripts/components/setup-rootfs.sh`. This keeps static system files in
Git instead of embedding large `echo` blocks inside build scripts.
