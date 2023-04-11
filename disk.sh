#!/usr/bin/env bash
set -eu

IMG="/storage"
FILE="$IMG/boot.img"
[ ! -f "$FILE" ] && echo "ERROR: Boot image does not exist ($FILE)" && exit 81

DISK_SIZE=$(echo "${DISK_SIZE}" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
NEW_SIZE=$(numfmt --from=iec "${DISK_SIZE}")

FILE="$IMG/data${DISK_SIZE}.img"
[ ! -f "$FILE" ] && truncate -s "${NEW_SIZE}" "${FILE}"
[ ! -f "$FILE" ] && echo "ERROR: Data image does not exist ($FILE)" && exit 83

KVM_DISK_OPTS="\
    -drive id=cdrom0,if=none,format=raw,readonly=on,file=${IMG}/boot.img \  
    -device virtio-scsi-pci,id=scsi0 \  
    -device scsi-cd,bus=scsi0.0,drive=cdrom0 \  
    -device virtio-scsi-pci,id=hw-userdata,bus=pcie.0,addr=0xa \
    -drive file=${IMG}/data${DISK_SIZE}.img,if=none,id=drive-userdata,format=raw,cache=none,aio=native,discard=on,detect-zeroes=on \
    -device scsi-hd,bus=hw-userdata.0,channel=0,scsi-id=0,lun=0,drive=drive-userdata,id=userdata0,rotation_rate=1,bootindex=1"

