#!/usr/bin/env bash
set -Eeuo pipefail

# Display wait message
html "Please wait while the container is being started..."
/run/server.sh &

# Check if running with interactive TTY or redirected to docker log
if [ -t 1 ]; then
  PROGRESS="--progress=bar:noscroll"
else
  PROGRESS="--progress=dot:giga"
fi

BASE="boot.img"
[ -f "$STORAGE/$BASE" ] && return 0

if [ -z "$BOOT" ]; then
  error "No boot disk specified, set BOOT= to the URL of an ISO file." && exit 64
fi

BASE=$(basename "$BOOT")
[ -f "$STORAGE/$BASE" ] && return 0

BASE=$(basename "${BOOT%%\?*}")
: "${BASE//+/ }"; printf -v BASE '%b' "${_//%/\\x}"
BASE=$(echo "$BASE" | sed -e 's/[^A-Za-z0-9._-]/_/g')
[ -f "$STORAGE/$BASE" ] && return 0

TMP="$STORAGE/${BASE%.*}.tmp"
rm -f "$TMP"

MSG="Downloading $BASE as boot image..."
info "$MSG" && html "$MSG"

{ wget "$BOOT" -O "$TMP" -q --no-check-certificate --show-progress "$PROGRESS"; rc=$?; } || :

(( rc != 0 )) && error "Failed to download $BOOT, reason: $rc" && exit 60
[ ! -f "$TMP" ] && error "Failed to download $BOOT" && exit 61

SIZE=$(stat -c%s "$TMP")

if ((SIZE<100000)); then
  error "Invalid ISO file: Size is smaller than 100 KB" && exit 62
fi

mv -f "$TMP" "$STORAGE/$BASE"

html "Download finished, booting container..."
return 0
