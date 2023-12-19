#!/usr/bin/env bash
set -Eeuo pipefail

info () { printf "%b%s%b" "\E[1;34m❯ \E[1;36m" "$1" "\E[0m\n"; }
error () { printf "%b%s%b" "\E[1;31m❯ " "ERROR: $1" "\E[0m\n" >&2; }

trap 'error "Status $? while: $BASH_COMMAND (line $LINENO/$BASH_LINENO)"' ERR

[ ! -f "/run/entry.sh" ] && error "Script must run inside Docker container!" && exit 11
[ "$(id -u)" -ne "0" ] && error "Script must be executed with root privileges." && exit 12

# Docker environment variables

: ${BOOT:=''}           # URL of the ISO file
: ${KVM:='Y'}           # Enable KVM acceleration
: ${DEBUG:='N'}         # Disable debugging mode
: ${ALLOCATE:='N'}      # Disable preallocation
: ${ARGUMENTS:=''}      # Extra QEMU parameters
: ${CPU_CORES:='1'}     # Amount of CPU cores
: ${RAM_SIZE:='1G'}     # Maximum RAM amount
: ${DISK_SIZE:='16G'}   # Initial data disk size

# Helper variables

KERNEL=$(uname -r | cut -b 1)
MINOR=$(uname -r | cut -d '.' -f2)
ARCH=$(dpkg --print-architecture)
VERS=$(qemu-system-x86_64 --version | head -n 1 | cut -d '(' -f 1)

# Check folder

STORAGE="/storage"
[ ! -d "$STORAGE" ] && error "Storage folder ($STORAGE) not found!" && exit 13

# Helper functions

addPackage () {

  local pkg=$1
  local desc=$2

  if apt-mark showinstall | grep -qx "$pkg"; then
    return 0
  fi

  info "Installing $desc..."

  export DEBCONF_NOWARNINGS="yes"
  export DEBIAN_FRONTEND="noninteractive"

  apt-get -qq update
  apt-get -qq --no-install-recommends -y install "$pkg" > /dev/null

  return 0
}

return 0
