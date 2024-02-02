#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: "${KVM:="Y"}"
: "${CPU_FLAGS:=""}"
: "${CPU_MODEL:="host"}"

[[ "$ARCH" != "arm"* ]] && KVM="N"

if [[ "$KVM" != [Nn]* ]]; then

  KVM_ERR=""

  if [ ! -e /dev/kvm ]; then
    KVM_ERR="(device file missing)"
  else
    if ! sh -c 'echo -n > /dev/kvm' &> /dev/null; then
      KVM_ERR="(no write access)"
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

  if [[ "${BOOT_MODE,,}" == "windows" ]] || [[ "${BOOT_MODE,,}" == "windows_legacy" ]]; then

    CPU_FEATURES="kvm=on,+hypervisor,+invtsc,l3-cache=on,migratable=no,hv_passthrough"

  fi

else

  KVM_OPTS=""
  CPU_FEATURES=""

  if [[ "${CPU_MODEL,,}" == "host"* ]]; then

    if [[ "$ARCH" == "arm"* ]]; then
      CPU_MODEL="max"
    else
      CPU_MODEL="cortex-a76"
    fi

  fi
fi

if [ -z "$CPU_FLAGS" ]; then
  CPU_FLAGS="$CPU_MODEL,$CPU_FEATURES"
else
  CPU_FLAGS="$CPU_MODEL,$CPU_FEATURES,$CPU_FLAGS"
fi

return 0
