#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${DISPLAY:='none'}    # Display type

case "$DISPLAY" in
  vnc)
    DISPLAY_OPTS="-nographic -vga std -vnc :0"
    ;;
  *)
    DISPLAY_OPTS="-nographic -display none"
    ;;
esac
