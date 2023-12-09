#!/usr/bin/env bash
set -Eeuo pipefail

KVM_ERR=""
KVM_OPTS=""

if [ -e /dev/kvm ] && sh -c 'echo -n > /dev/kvm' &> /dev/null; then
  if ! grep -q -e vmx -e svm /proc/cpuinfo; then
    KVM_ERR="(vmx/svm disabled)"
  fi
else
  [ -e /dev/kvm ] && KVM_ERR="(no write access)" || KVM_ERR="(device file missing)"
fi

if [ -n "$KVM_ERR" ]; then
  if [ "$ARCH" == "amd64" ]; then
    error "KVM acceleration not detected $KVM_ERR, see the FAQ about this."
    [[ "$DEBUG" != [Yy1]* ]] && exit 88
  fi
else
  KVM_OPTS=",accel=kvm -enable-kvm -cpu host"
fi

DEF_OPTS="-nodefaults"
RAM_OPTS=$(echo "-m $RAM_SIZE" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
CPU_OPTS="-smp $CPU_CORES,sockets=1,dies=1,cores=$CPU_CORES,threads=1"
MAC_OPTS="-machine type=q35,usb=off,dump-guest-core=off,hpet=off${KVM_OPTS}"
SERIAL_OPTS="-serial mon:stdio -device virtio-serial-pci,id=virtio-serial0,bus=pcie.0,addr=0x3"
EXTRA_OPTS="-device virtio-balloon-pci,id=balloon0 -object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng-pci,rng=rng0"

ARGS="$DEF_OPTS $CPU_OPTS $RAM_OPTS $MAC_OPTS $SERIAL_OPTS $NET_OPTS $DISK_OPTS $DISPLAY_OPTS $EXTRA_OPTS $ARGUMENTS"
ARGS=$(echo "$ARGS" | sed 's/\t/ /g' | tr -s ' ')

return 0
