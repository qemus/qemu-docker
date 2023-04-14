#!/usr/bin/env bash
set -eu

FILE="$IMG/boot.img"
rm -f "$FILE"

echo "Downloading $BOOT..."

# Check if running with interactive TTY or redirected to docker log
if [ -t 1 ]; then
  wget "$BOOT" -O "$FILE".tmp -q --no-check-certificate --show-progress
else
  wget "$BOOT" -O "$FILE".tmp -q --no-check-certificate --show-progress --progress=dot:giga
fi

[ ! -f "$FILE".tmp ] && echo "Download failed" && exit 61

mv -f "$FILE".tmp "$FILE"
