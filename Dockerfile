FROM ubuntu:18.04 as qemu-builder
ARG QEMU_VERSION=4.0.0
WORKDIR /src
RUN apt-get update
RUN apt-get install -y \
  wget \
  python \
  build-essential \
  gcc \
  pkg-config \
  git \
  bison \
  flex \
  libglib2.0-dev \
  libfdt-dev \
  libpixman-1-dev \
  zlib1g-dev
RUN wget -nv "http://wiki.qemu-project.org/download/qemu-$QEMU_VERSION.tar.bz2"
RUN tar -xjf "qemu-$QEMU_VERSION.tar.bz2"
WORKDIR /src/qemu-$QEMU_VERSION
RUN ./configure \
  --prefix="/usr/local/qemu" \
  --target-list="arm-softmmu arm-linux-user" \
  --disable-docs \
  --disable-sdl \
  --disable-gtk \
  --disable-gnutls \
  --disable-gcrypt \
  --disable-nettle \
  --disable-curses \
  --static
RUN make -j2
RUN make install

FROM golang:1-buster as builder
WORKDIR /src
RUN git clone https://github.com/solo-io/packer-builder-arm-image
WORKDIR /src/packer-builder-arm-image
RUN go mod download
RUN go build

# light @ v1.6.6
FROM hashicorp/packer:light@sha256:523457b5371562c4d9c21621ee85c71c31e7ff53d5ec303a5daf07c55531b84e
RUN apk add --no-cache libc6-compat
COPY --from=qemu-builder /usr/local/qemu /usr/local/qemu
RUN ln -s /usr/local/qemu/bin/qemu-arm /usr/local/bin/qemu-arm-static
COPY --from=builder /src/packer-builder-arm-image/packer-builder-arm-image /bin/packer-builder-arm-image
COPY "entrypoint.sh" "/entrypoint.sh"
ENTRYPOINT ["/entrypoint.sh"]
