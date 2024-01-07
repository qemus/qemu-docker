#!/usr/bin/env bash
set -Eeuo pipefail

FILE="$STORAGE/boot.img"
[ -f "$FILE" ] && return 0

# Check if running with interactive TTY or redirected to docker log
if [ -t 1 ]; then
  PROGRESS="--progress=bar:noscroll"
else
  PROGRESS="--progress=dot:giga"
fi

if [[ "${BOOT_MODE,,}" == "windows" ]]; then

  TMP="$STORAGE/drivers.tmp"
  rm -f "$TMP"

  info "Downloading VirtIO drivers for Windows..."
  DRIVERS="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"

  { wget "$DRIVERS" -O "$TMP" -q --no-check-certificate --show-progress "$PROGRESS"; rc=$?; } || :

  if (( rc == 0 )); then
    mv -f "$TMP" "$STORAGE/drivers.iso"
  else
    info "Failed to download $DRIVERS, reason: $rc"
  fi
fi

TMP="$STORAGE/boot.tmp"
rm -f "$TMP"

BASE=$(basename "$BOOT")
info "Downloading $BASE as boot image..."

[[ "$DEBUG" == [Yy1]* ]] && set -x

{ wget "$BOOT" -O "$TMP" -q --no-check-certificate --show-progress "$PROGRESS"; rc=$?; } || :

(( rc != 0 )) && error "Failed to download $BOOT, reason: $rc" && exit 60
[ ! -f "$TMP" ] && error "Failed to download $BOOT" && exit 61

SIZE=$(stat -c%s "$TMP")

if ((SIZE<100000)); then
  error "Invalid ISO file: Size is smaller than 100 KB" && exit 62
fi

mv -f "$TMP" "$FILE"

{ set +x; } 2>/dev/null
[[ "$DEBUG" == [Yy1]* ]] && echo

return 0
