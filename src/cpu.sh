#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${CPU_MODEL:='host'}
: ${CPU_FEATURES:='+ssse3,+sse4.1,+sse4.2'}

KVM_ERR=""
KVM_OPTS=""

if [[ "$ARCH" == "amd64" && "$KVM" != [Nn]* ]]; then

  if [ -e /dev/kvm ] && sh -c 'echo -n > /dev/kvm' &> /dev/null; then
    if ! grep -q -e vmx -e svm /proc/cpuinfo; then
      KVM_ERR="(vmx/svm disabled)"
    fi
  else
    [ -e /dev/kvm ] && KVM_ERR="(no write access)" || KVM_ERR="(device file missing)"
  fi

  if [ -n "$KVM_ERR" ]; then
    error "KVM acceleration not detected $KVM_ERR, this will cause a major loss of performance."
    error "See the FAQ on how to enable it, or skip this error by setting KVM=N (not recommended)."
    [[ "$DEBUG" != [Yy1]* ]] && exit 88
    [[ "$CPU_MODEL" == "host"* ]] && CPU_MODEL="max,$CPU_FEATURES"
  else
    KVM_OPTS=",accel=kvm -enable-kvm"
  fi

else

  if [[ "$CPU_MODEL" == "host"* ]]; then
    if [[ "$ARCH" == "amd64" ]]; then
      CPU_MODEL="max,$CPU_FEATURES"
    else
      CPU_MODEL="qemu64,$CPU_FEATURES"
    fi
  fi

fi

return 0
