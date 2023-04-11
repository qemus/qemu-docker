#!/usr/bin/env bash
set -eu

IMG="/storage"
[ ! -d "$IMG" ] && echo "Storage folder (${IMG}) not found!" && exit 69

FILE="$IMG/boot.img"
[ -f "$FILE" ] && exit 0

echo "Downloading $BOOT..."

# Check if running with interactive TTY or redirected to docker log
if [ -t 1 ]; then
  wget "$BOOT" -O "$FILE".tmp -q --no-check-certificate --show-progress
else
  wget "$BOOT" -O "$FILE".tmp -q --no-check-certificate --show-progress --progress=dot:giga
fi

[ ! -f "$FILE".tmp ] && echo "Download failed" && exit 61

mv -f "$FILE".tmp "$FILE"
