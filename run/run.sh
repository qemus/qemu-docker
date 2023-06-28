#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${BOOT:=''}           # URL of the ISO file
: ${DEBUG:='N'}         # Enable debug mode
: ${ALLOCATE:='Y'}      # Preallocate diskspace
: ${CPU_CORES:='1'}     # Amount of CPU cores
: ${DISK_SIZE:='16G'}   # Initial data disk size
: ${RAM_SIZE:='512M'}   # Maximum RAM amount

echo "❯ Starting QEMU for Docker v${VERSION}..."

info () { echo -e "\E[1;34m❯ \E[1;36m$1\E[0m" ; }
error () { echo -e >&2 "\E[1;31m❯ ERROR: $1\E[0m" ; }
trap 'error "Status $? while: ${BASH_COMMAND} (line $LINENO/$BASH_LINENO)"' ERR

[ ! -f "/run/run.sh" ] && error "Script must run inside Docker container!" && exit 11
[ "$(id -u)" -ne "0" ] && error "Script must be executed with root privileges." && exit 12

STORAGE="/storage"
KERNEL=$(uname -r | cut -b 1)
ARCH=$(dpkg --print-architecture)
VERS=$(qemu-system-x86_64 --version | head -n 1 | cut -d '(' -f 1)

[ ! -d "$STORAGE" ] && error "Storage folder (${STORAGE}) not found!" && exit 13

if [ ! -f "$STORAGE/boot.img" ]; then
  . /run/install.sh
fi

# Initialize disks
. /run/disk.sh

# Initialize network
. /run/network.sh

# Configure shutdown
. /run/power.sh

KVM_ERR=""
KVM_OPTS=""

if [ -e /dev/kvm ] && sh -c 'echo -n > /dev/kvm' &> /dev/null; then
  if ! grep -q -e vmx -e svm /proc/cpuinfo; then
    KVM_ERR="(vmx/svm disabled)"
  fi
else
  [ -e /dev/kvm ] && KVM_ERR="(no write access)" || KVM_ERR="(device file missing)"
fi

if [ -n "${KVM_ERR}" ]; then
  if [ "$ARCH" == "amd64" ]; then
    error "KVM acceleration not detected ${KVM_ERR}, see the FAQ about this."
    [[ "${DEBUG}" != [Yy1]* ]] && exit 88
  fi
else
  KVM_OPTS=",accel=kvm -enable-kvm -cpu host"
fi

DEF_OPTS="-nographic -nodefaults -display none"
RAM_OPTS=$(echo "-m ${RAM_SIZE}" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
CPU_OPTS="-smp ${CPU_CORES},sockets=1,dies=1,cores=${CPU_CORES},threads=1"
MAC_OPTS="-machine type=q35,usb=off,dump-guest-core=off,hpet=off${KVM_OPTS}"
SERIAL_OPTS="-serial mon:stdio -device virtio-serial-pci,id=virtio-serial0,bus=pcie.0,addr=0x3"
EXTRA_OPTS="-device virtio-balloon-pci,id=balloon0 -object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng-pci,rng=rng0"

env | grep -iq QEMU_EXTRA_ARGS || QEMU_EXTRA_ARGS=""

ARGS="${DEF_OPTS} ${CPU_OPTS} ${RAM_OPTS} ${MAC_OPTS} ${MON_OPTS} ${SERIAL_OPTS} ${NET_OPTS} ${DISK_OPTS} ${EXTRA_OPTS} ${QEMU_EXTRA_ARGS}"
ARGS=$(echo "$ARGS" | sed 's/\t/ /g' | tr -s ' ')

echo "Running with arguments: ${ARGS}"

trap - ERR

set -m
(
  [[ "${DEBUG}" == [Yy1]* ]] && info "$VERS" && set -x
  qemu-system-x86_64 ${ARGS:+ $ARGS} & echo $! > "${_QEMU_PID}"
  { set +x; } 2>/dev/null
)
set +m

if (( KERNEL > 4 )); then
  pidwait -F "${_QEMU_PID}" & wait $!
else
  tail --pid "$(cat "${_QEMU_PID}")" --follow /dev/null & wait $!
fi
