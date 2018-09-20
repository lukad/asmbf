FROM debian:stable-slim

RUN mkdir /build
WORKDIR /build

RUN apt-get update && apt-get install -y \
  make \
  nasm \
  binutils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY Makefile *.asm ./

RUN make
