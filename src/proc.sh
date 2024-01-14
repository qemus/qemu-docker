#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: "${KVM:='Y'}"
: "${CPU_MODEL:='host'}"
: "${CPU_FEATURES:='+ssse3,+sse4.1,+sse4.2'}"

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

  KVM_OPTS=",accel=kvm -enable-kvm"

else

  KVM_OPTS=""

  if [[ "$CPU_MODEL" == "host"* ]]; then
    if [[ "$ARCH" == "amd64" ]]; then
      CPU_MODEL="max,$CPU_FEATURES"
    else
      CPU_MODEL="qemu64,$CPU_FEATURES"
    fi
  fi

fi

return 0
