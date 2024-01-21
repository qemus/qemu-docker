#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: "${KVM:="Y"}"
: "${CPU_FLAGS:=""}"
: "${CPU_MODEL:="host"}"

[ "$ARCH" != "amd64" ] && KVM="N"

if [[ "$KVM" != [Nn]* ]]; then

  KVM_ERR=""

  if [ ! -e /dev/kvm ]; then
    KVM_ERR="(device file missing)"
  else
    if ! sh -c 'echo -n > /dev/kvm' &> /dev/null; then
      KVM_ERR="(no write access)"
    else
      if ! grep -q -e vmx -e svm /proc/cpuinfo; then
        KVM_ERR="(vmx/svm disabled)"
      fi
    fi
  fi

  if [ -n "$KVM_ERR" ]; then
    KVM="N"
    error "KVM acceleration not detected $KVM_ERR, this will cause a major loss of performance."
    error "See the FAQ on how to enable it, or continue without KVM by setting KVM=N (not recommended)."
    [[ "$DEBUG" != [Yy1]* ]] && exit 88
  fi

fi

if [[ "$KVM" != [Nn]* ]]; then

  CPU_FEATURES="kvm=on"
  KVM_OPTS=",accel=kvm -enable-kvm"

  if [[ "${BOOT_MODE,,}" == "windows" ]]; then

    CPU_FEATURES="kvm=on,+hypervisor,+invtsc,l3-cache=on,migratable=no,hv_passthrough"

  fi

else

  KVM_OPTS=""
  CPU_FEATURES="+ssse3,+sse4.1,+sse4.2"

  if [[ "${CPU_MODEL,,}" == "host"* ]]; then

    if [[ "$ARCH" == "amd64" ]]; then
      CPU_MODEL="max"
    else
      CPU_MODEL="qemu64"
    fi

  fi
fi

if [ -z "$CPU_FLAGS" ]; then
  CPU_FLAGS="$CPU_MODEL,$CPU_FEATURES"
else
  CPU_FLAGS="$CPU_MODEL,$CPU_FEATURES,$CPU_FLAGS"
fi

return 0
