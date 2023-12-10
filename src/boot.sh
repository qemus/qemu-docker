#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${BOOT_MODE:='legacy'}  # Display type

case "${BOOT_MODE,,}" in
  uefi)
    BOOT_OPTS="-bios /usr/share/OVMF/OVMF_CODE.fd"
    ;;
  legacy)
    BOOT_OPTS=""
    ;;
  *)
    info "Unknown boot mode '${BOOT_MODE}', defaulting to 'legacy'"
    BOOT_OPTS=""
    ;;
esac

return 0
