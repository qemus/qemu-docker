#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${GPU:='N'}           # GPU passthrough
: ${DISPLAY:='none'}    # Display type

case "${DISPLAY,,}" in
  vnc)
    if [[ "$GPU" != [Yy1]* ]] || [[ "$ARCH" != "amd64" ]]; then
      DISPLAY_OPTS="-nographic -vga std -vnc :0"
    else
      DISPLAY_OPTS="-vga std -vnc :0"
    fi
    ;;
  *)
    if [[ "$GPU" != [Yy1]* ]] || [[ "$ARCH" != "amd64" ]]; then
      DISPLAY_OPTS="-nographic -display none"
    else
      DISPLAY_OPTS=""
    fi
    ;;
esac

if [[ "$GPU" != [Yy1]* ]] || [[ "$ARCH" != "amd64" ]]; then
  return 0
fi

[ ! -d /dev/dri ] && mkdir -m 755 /dev/dri

if [ ! -c /dev/dri/card0 ]; then
  if mknod /dev/dri/card0 c 226 0; then
    chmod 666 /dev/dri/card0
  fi
fi

if [ ! -c /dev/dri/renderD128 ]; then
  if mknod /dev/dri/renderD128 c 226 128; then
    chmod 666 /dev/dri/renderD128
  fi
fi

addPackage "xserver-xorg-video-intel" "Intel GPU drivers"
addPackage "qemu-system-modules-opengl" "OpenGL module"

DISPLAY_OPTS="$DISPLAY_OPTS -display egl-headless,rendernode=/dev/dri/renderD128"
DISPLAY_OPTS="$DISPLAY_OPTS -device virtio-vga,id=video0,max_outputs=1,bus=pcie.0,addr=0x1"

return 0
