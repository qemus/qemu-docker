#!/usr/bin/env bash
set -Eeuo pipefail

APP="QEMU"
SUPPORT="https://github.com/qemus/qemu-docker"

echo "❯ Starting $APP for Docker v$(</run/version)..."
echo "❯ For support visit $SUPPORT"
echo

cd /run

. reset.sh      # Initialize system
. install.sh    # Get bootdisk
. disk.sh       # Initialize disks
. display.sh    # Initialize graphics
. network.sh    # Initialize network
. boot.sh       # Configure boot
. proc.sh       # Initialize processor
. config.sh     # Configure arguments

trap - ERR

if [[ "${DISPLAY,,}" == "web" ]]; then
  nginx -e stderr
fi

info "Booting image using $VERS..."

[[ "$DEBUG" == [Yy1]* ]] && set -x
exec qemu-system-x86_64 ${ARGS:+ $ARGS}
