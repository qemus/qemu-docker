#!/usr/bin/env bash
set -eu

echo "Starting QEMU..."

STORAGE="/storage"
[ ! -d "$STORAGE" ] && echo "Storage folder (${STORAGE}) not found!" && exit 69

if [ -f "$STORAGE/boot.img" ]; then
  . /run/install.sh
fi

# Initialize disks
. /run/disk.sh

# Initialize network
. /run/network.sh

# Configure shutdown
. /run/power.sh

KVM_ACC_OPTS=""

if [ -e /dev/kvm ] && sh -c 'echo -n > /dev/kvm' &> /dev/null; then
  if [[ $(grep -e vmx -e svm /proc/cpuinfo) ]]; then
    KVM_ACC_OPTS="-machine type=q35,usb=off,accel=kvm -enable-kvm -cpu host"
  fi
fi

[ -z "${KVM_ACC_OPTS}" ] && echo "Error: KVM acceleration is disabled.." && exit 88

RAM_SIZE=$(echo "${RAM_SIZE}" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
KVM_SERIAL_OPTS="-serial mon:stdio -device virtio-serial-pci,id=virtio-serial0,bus=pcie.0,addr=0x3"
EXTRA_OPTS="-nographic -object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng-pci,rng=rng0 -device virtio-balloon-pci,id=balloon0,bus=pcie.0,addr=0x4"
ARGS="-m ${RAM_SIZE} -smp ${CPU_CORES} ${KVM_ACC_OPTS} ${EXTRA_OPTS} ${KVM_MON_OPTS} ${KVM_SERIAL_OPTS} ${KVM_NET_OPTS} ${KVM_DISK_OPTS}"

set -m
(
  qemu-system-x86_64 ${ARGS} & echo $! > ${_QEMU_PID}
)
set +m

# Since we have to start the process with -m, we need to poll every intervall if it's still running
while [ -d "/proc/$(cat ${_QEMU_PID})"  ]; do
  sleep 1
done
