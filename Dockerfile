FROM alpine:latest

RUN apk add --no-cache \
    autoconf \
    automake \
    bash \
    bc \
    binutils \
    bison \
    build-base \
    ca-certificates \
    coreutils \
    cpio \
    curl \
    dosfstools \
    e2fsprogs \
    elfutils-dev \
    file \
    findutils \
    flex \
    git \
    gzip \
    kmod \
    libarchive-tools \
    linux-headers \
    make \
    mtools \
    nasm \
    ncurses-dev \
    openssl-dev \
    patch \
    perl \
    pkgconf \
    rsync \
    tar \
    wget \
    xorriso \
    xz \
    zlib-dev

WORKDIR /workspace

CMD ["/bin/bash"]
