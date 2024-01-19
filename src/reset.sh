#!/usr/bin/env bash
set -Eeuo pipefail

info () { printf "%b%s%b" "\E[1;34m❯ \E[1;36m" "$1" "\E[0m\n"; }
error () { printf "%b%s%b" "\E[1;31m❯ " "ERROR: $1" "\E[0m\n" >&2; }
warn () { printf "%b%s%b" "\E[1;31m❯ " "Warning: $1" "\E[0m\n" >&2; }

trap 'error "Status $? while: $BASH_COMMAND (line $LINENO/$BASH_LINENO)"' ERR

[ ! -f "/run/entry.sh" ] && error "Script must run inside Docker container!" && exit 11
[ "$(id -u)" -ne "0" ] && error "Script must be executed with root privileges." && exit 12

# Docker environment variables

: "${BOOT:=""}"           # URL of the ISO file
: "${DEBUG:="N"}"         # Disable debugging
: "${ALLOCATE:=""}"       # Preallocate diskspace
: "${ARGUMENTS:=""}"      # Extra QEMU parameters
: "${CPU_CORES:="1"}"     # Amount of CPU cores
: "${RAM_SIZE:="1G"}"     # Maximum RAM amount
: "${DISK_SIZE:="16G"}"   # Initial data disk size

# Helper variables

STORAGE="/storage"
PAGE="/dev/shm/index.html"
TEMPLATE="/var/www/index.html"

KERNEL=$(uname -r | cut -b 1)
MINOR=$(uname -r | cut -d '.' -f2)
ARCH=$(dpkg --print-architecture)
VERS=$(qemu-system-x86_64 --version | head -n 1 | cut -d '(' -f 1)
FOOTER="$APP for Docker v$(</run/version)<BR/>For support visit $SUPPORT"

# Check folder
[ ! -d "$STORAGE" ] && error "Storage folder ($STORAGE) not found!" && exit 13

# Helper functions

fKill () {
  local name=$1

  { pkill -f "$name" || true; } 2>/dev/null

  while pgrep -f -l "$name" >/dev/null; do
    sleep 0.1
  done

  return 0
}

html()
{
    local timeout="$2"
    [ -z "$timeout" ] && timeout="4999"
    local body="$1<script>setTimeout(() => { document.location.reload(); }, $timeout);</script>"
    
    local HTML
    HTML=$(<"$TEMPLATE")
    HTML="${HTML/[1]/$APP}"
    HTML="${HTML/[2]/$body}"
    HTML="${HTML/[3]/$FOOTER}"

    printf '%b' "HTTP/1.1 200 OK\nContent-Length: ${#HTML}\nConnection: close\n\n$HTML" > "$PAGE"
    return 0
}

addPackage () {

  local pkg=$1
  local desc=$2

  if apt-mark showinstall | grep -qx "$pkg"; then
    return 0
  fi

  MSG="Installing $desc..."
  info "$MSG" && html "$MSG"

  DEBIAN_FRONTEND=noninteractive apt-get -qq update
  DEBIAN_FRONTEND=noninteractive apt-get -qq --no-install-recommends -y install "$pkg" > /dev/null

  return 0
}

return 0
