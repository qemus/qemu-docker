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
    -device virtio-scsi-pci,id=hw-boot,bus=pcie.0,addr=0xa \
    -drive file=${IMG}/boot.img,if=none,id=drive-boot,format=raw,cache=none,aio=native,discard=on,detect-zeroes=on \
    -device scsi-hd,bus=hw-boot.0,channel=0,scsi-id=0,lun=0,drive=drive-boot,id=boot0,rotation_rate=1,bootindex=1 \
    -device virtio-scsi-pci,id=hw-userdata,bus=pcie.0,addr=0xb \
    -drive file=${IMG}/data${DISK_SIZE}.img,if=none,id=drive-userdata,format=raw,cache=none,aio=native,discard=on,detect-zeroes=on \
    -device scsi-hd,bus=hw-userdata.0,channel=0,scsi-id=0,lun=0,drive=drive-userdata,id=userdata0,rotation_rate=1,bootindex=2"

