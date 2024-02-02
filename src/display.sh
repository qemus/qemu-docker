#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: "${GPU:="N"}"         # GPU passthrough
: "${VGA:="virtio"}"    # VGA adaptor
: "${DISPLAY:="web"}"   # Display type

case "${DISPLAY,,}" in
  vnc)
    DISPLAY_OPTS="-display vnc=:0 -vga $VGA"
    ;;
  web)
    DISPLAY_OPTS="-display vnc=:0,websocket=5700 -vga $VGA"
    ;;
  none)
    DISPLAY_OPTS="-display none -vga none"
    ;;
  *)
    DISPLAY_OPTS="-display $DISPLAY -vga $VGA"
    ;;
esac

return 0
