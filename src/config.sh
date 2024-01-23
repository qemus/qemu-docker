#!/usr/bin/env bash
set -Eeuo pipefail

DEF_OPTS="-nodefaults"
SERIAL_OPTS="-serial mon:stdio"
USB_OPTS="-device qemu-xhci -device usb-tablet"
MON_OPTS="-monitor telnet:localhost:7100,server,nowait,nodelay"
RAM_OPTS=$(echo "-m $RAM_SIZE" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
CPU_OPTS="-cpu $CPU_FLAGS -smp $CPU_CORES,sockets=1,dies=1,cores=$CPU_CORES,threads=1"
MAC_OPTS="-machine type=q35${SECURE},graphics=off,vmport=off,dump-guest-core=off,hpet=off${KVM_OPTS}"
DEV_OPTS="-device virtio-balloon-pci,id=balloon0,bus=pcie.0,addr=0x4"
DEV_OPTS="$DEV_OPTS -object rng-random,id=objrng0,filename=/dev/urandom"
DEV_OPTS="$DEV_OPTS -device virtio-rng-pci,rng=objrng0,id=rng0,bus=pcie.0,addr=0x1c"

ARGS="$DEF_OPTS $CPU_OPTS $RAM_OPTS $MAC_OPTS $DISPLAY_OPTS $MON_OPTS $SERIAL_OPTS $NET_OPTS $DISK_OPTS $BOOT_OPTS $DEV_OPTS $USB_OPTS $ARGUMENTS"
ARGS=$(echo "$ARGS" | sed 's/\t/ /g' | tr -s ' ')

if [[ "${BOOT_MODE,,}" == "windows" ]]; then

  mkdir -p /dev/shm/tpm
  swtpm socket -t -d --tpmstate dir=/dev/shm/tpm --ctrl type=unixio,path=/dev/shm/tpm/swtpm-sock --tpm2

  if [ ! -f "/dev/shm/tpm/swtpm-sock" ]; then
    error "TPM socket not found?" && exit 46
  fi

fi

if [[ "${DISPLAY,,}" == "web" ]]; then
  rm -f /dev/shm/msg.html
  rm -f /dev/shm/index.html
else
  if [[ "${DISPLAY,,}" == "vnc" ]]; then
    html "You can now connect to VNC on port 5900." "0"
  else
    html "The virtual machine was booted successfully." "0"
  fi
fi

return 0
