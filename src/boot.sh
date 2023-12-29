#!/usr/bin/env bash
set -Eeuo pipefail

OVMF="/usr/share/OVMF"

# Docker environment variables

: ${BOOT_MODE:='legacy'}  # Boot mode

case "${BOOT_MODE,,}" in
  uefi)
    VARS="$OVMF/OVMF_VARS_4M.fd"
    [ ! -f "$VARS" ] && error "UEFI vars file ($VARS) not found!" && exit 44
    [ ! -f "$STORAGE/uefi.vars" ] && cp "$VARS" "$STORAGE/uefi.vars"
    BOOT_OPTS="-bios $OVMF/OVMF_CODE_4M.fd"
    BOOT_OPTS="$BOOT_OPTS -drive file=$STORAGE/uefi.vars,if=pflash,format=raw"
    ;;
  secure)
    VARS="$OVMF/OVMF_VARS_4M.secboot.fd"
    [ ! -f "$VARS" ] && error "UEFI vars file ($VARS) not found!" && exit 44
    [ ! -f "$STORAGE/uefi.vars" ] && cp "$VARS" "$STORAGE/uefi.vars"
    BOOT_OPTS="-bios $OVMF/OVMF_CODE_4M.secboot.fd"
    BOOT_OPTS="$BOOT_OPTS -drive file=$STORAGE/uefi.vars,if=pflash,format=raw"
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
