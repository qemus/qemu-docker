#!/usr/bin/env bash
set -eu

IMG="/storage"
[ ! -d "$IMG" ] && echo "Storage folder (${IMG}) not found!" && exit 69
[ -f "$IMG/boot.img" ] && exit 0

TMP="$IMG/tmp"

echo "Install: Downloading $BOOT..."

FILE="$TMP/boot.img"
rm -rf $TMP && mkdir -p $TMP

# Check if running with interactive TTY or redirected to docker log
if [ -t 1 ]; then
  wget "$BOOT" -O "$FILE" -q --no-check-certificate --show-progress
else
  wget "$BOOT" -O "$FILE" -q --no-check-certificate --show-progress --progress=dot:giga
fi

[ ! -f "$FILE" ] && echo "Download failed" && exit 61

mv -f "$BOOT" "$IMG"/boot.img

rm -rf $TMP

