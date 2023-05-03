#!/usr/bin/env bash
set -Eeuo pipefail

TMP="/boot.img"
rm -f "$TMP"

echo "Downloading ${BOOT} as boot image..."

# Check if running with interactive TTY or redirected to docker log
if [ -t 1 ]; then
  PROGRESS="--progress=bar:noscroll"
else
  PROGRESS="--progress=dot:giga"
fi

[ "$DEBUG" = "Y" ] && set -x

{ wget "$BOOT" -O "$TMP" -q --no-check-certificate --show-progress "$PROGRESS"; rc=$?; } || :
(( rc != 0 )) && echo "ERROR: Failed to download ${BOOT}, reason: $rc" && exit 60

[ ! -f "$TMP" ] && echo "Failed to download ${BOOT}" && exit 61

SIZE=$(stat -c%s "$TMP")

if ((SIZE<100000)); then
  echo "Invalid ISO file: Size is smaller than 100 KB" && exit 62
fi

FILE="$STORAGE/boot.img"

mv -f "$TMP" "$FILE"

{ set +x; } 2>/dev/null
[ "$DEBUG" = "Y" ] && echo

return 0
