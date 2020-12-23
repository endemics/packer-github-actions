FROM golang:1-buster as builder
WORKDIR /src
RUN git clone https://github.com/solo-io/packer-builder-arm-image
WORKDIR /src/packer-builder-arm-image
RUN go mod download
RUN go build

# light @ v1.6.6
FROM hashicorp/packer:light@sha256:523457b5371562c4d9c21621ee85c71c31e7ff53d5ec303a5daf07c55531b84e

RUN apk add --no-cache libc6-compat
COPY --from=builder /src/packer-builder-arm-image/packer-builder-arm-image /bin/packer-builder-arm-image

COPY "entrypoint.sh" "/entrypoint.sh"

ENTRYPOINT ["/entrypoint.sh"]
