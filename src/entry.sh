#!/usr/bin/env bash
set -Eeuo pipefail

echo "❯ Starting QEMU for Docker v$(</run/version)..."
echo "❯ For support visit https://github.com/qemu-tools/qemu-docker/"

cd /run

. reset.sh      # Initialize system
. install.sh    # Get bootdisk
. disk.sh       # Initialize disks
. display.sh    # Initialize display
. network.sh    # Initialize network
. config.sh     # Configure arguments

trap - ERR
info "Booting image using ${VERS}..."

[[ "${DEBUG}" == [Yy1]* ]] && set -x
exec qemu-system-x86_64 ${ARGS:+ $ARGS}
{ set +x; } 2>/dev/null
