#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${DISK_IO:='native'}    # I/O Mode, can be set to 'native', 'threads' or 'io_turing'
: ${DISK_CACHE:='none'}   # Caching mode, can be set to 'writeback' for better performance
: ${DISK_DISCARD:='on'}   # Controls whether unmap (TRIM) commands are passed to the host.
: ${DISK_ROTATION:='1'}   # Rotation rate, set to 1 for SSD storage and increase for HDD

DISK_OPTS=""
BOOT="$STORAGE/boot.img"

if [ -f "$BOOT" ]; then
  DISK_OPTS="${DISK_OPTS} \
    -device virtio-scsi-pci,id=scsi0 \
    -drive id=cdrom0,if=none,format=raw,readonly=on,file=${BOOT} \
    -device scsi-cd,bus=scsi0.0,drive=cdrom0,bootindex=10"
fi

addDisk () {

  local GB
  local DIR
  local REQ
  local SIZE
  local SPACE
  local MIN_SIZE
  local CUR_SIZE
  local DATA_SIZE
  local DISK_ID=$1
  local DISK_FILE=$2
  local DISK_DESC=$3
  local DISK_SPACE=$4
  local DISK_INDEX=$5
  local DISK_ADDRESS=$6

  DIR=$(dirname "${DISK_FILE}")
  [ ! -d "${DIR}" ] && return 0

  [ -z "$DISK_SPACE" ] && DISK_SPACE="16G"
  DISK_SPACE=$(echo "${DISK_SPACE}" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
  DATA_SIZE=$(numfmt --from=iec "${DISK_SPACE}")

  if [ -f "${DISK_FILE}" ]; then

    CUR_SIZE=$(stat -c%s "${DISK_FILE}")

    if [ "$DATA_SIZE" -gt "$CUR_SIZE" ]; then

      GB=$(( (CUR_SIZE + 1073741823)/1073741824 ))
      info "Resizing ${DISK_DESC} from ${GB}G to ${DISK_SPACE} .."

      if [[ "${ALLOCATE}" == [Nn]* ]]; then

        # Resize file by changing its length
        if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
          error "Could not resize ${DISK_DESC} file (${DISK_FILE}) to ${DISK_SPACE} .." && exit 85
        fi

      else

        REQ=$((DATA_SIZE-CUR_SIZE))

        # Check free diskspace
        SPACE=$(df --output=avail -B 1 "${DIR}" | tail -n 1)

        if (( REQ > SPACE )); then
          error "Not enough free space to resize ${DISK_DESC} to ${DISK_SPACE} .."
          error "Specify a smaller size or disable preallocation with ALLOCATE=N." && exit 84
        fi

        # Resize file by allocating more space
        if ! fallocate -l "${DISK_SPACE}" "${DISK_FILE}"; then
          if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
            error "Could not resize ${DISK_DESC} file (${DISK_FILE}) to ${DISK_SPACE} .." && exit 85
          fi
        fi

      fi
    fi
  fi

  if [ ! -f "${DISK_FILE}" ]; then

    if [[ "${ALLOCATE}" == [Nn]* ]]; then

      # Create an empty file
      if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
        rm -f "${DISK_FILE}"
        error "Could not create a file for ${DISK_DESC} (${DISK_FILE})" && exit 87
      fi

    else

      # Check free diskspace
      SPACE=$(df --output=avail -B 1 "${DIR}" | tail -n 1)

      if (( DATA_SIZE > SPACE )); then
        error "Not enough free space to create ${DISK_DESC} of ${DISK_SPACE} .."
        error "Specify a smaller size or disable preallocation with ALLOCATE=N." && exit 86
      fi

      # Create an empty file
      if ! fallocate -l "${DISK_SPACE}" "${DISK_FILE}"; then
        if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
          rm -f "${DISK_FILE}"
          error "Could not create a file for ${DISK_DESC} (${DISK_FILE}) of ${DISK_SPACE} .." && exit 87
        fi
      fi

    fi
  fi

  DISK_OPTS="${DISK_OPTS} \
    -device virtio-scsi-pci,id=hw-${DISK_ID},bus=pcie.0,addr=${DISK_ADDRESS} \
    -drive file=${DISK_FILE},if=none,id=drive-${DISK_ID},format=raw,cache=${DISK_CACHE},aio=${DISK_IO},discard=${DISK_DISCARD},detect-zeroes=on \
    -device scsi-hd,bus=hw-${DISK_ID}.0,channel=0,scsi-id=0,lun=0,drive=drive-${DISK_ID},id=${DISK_ID},rotation_rate=${DISK_ROTATION},bootindex=${DISK_INDEX}"

  return 0
}

DISK1_FILE="${STORAGE}/data.img"
DISK2_FILE="/storage2/data2.img"
DISK3_FILE="/storage3/data3.img"
DISK4_FILE="/storage4/data4.img"
DISK5_FILE="/storage5/data5.img"
DISK6_FILE="/storage6/data6.img"

: ${DISK2_SIZE:=''}
: ${DISK3_SIZE:=''}
: ${DISK4_SIZE:=''}
: ${DISK5_SIZE:=''}
: ${DISK6_SIZE:=''}

addDisk "userdata" "${DISK1_FILE}" "disk" "${DISK_SIZE}" "1" "0xa"
addDisk "userdata2" "${DISK2_FILE}" "disk2" "${DISK2_SIZE}" "2" "0xb"
addDisk "userdata3" "${DISK3_FILE}" "disk3" "${DISK3_SIZE}" "3" "0xc"
addDisk "userdata4" "${DISK4_FILE}" "disk4" "${DISK4_SIZE}" "4" "0xd"
addDisk "userdata5" "${DISK5_FILE}" "disk5" "${DISK5_SIZE}" "5" "0xe"
addDisk "userdata6" "${DISK6_FILE}" "disk6" "${DISK6_SIZE}" "6" "0xf"

addDevice () {

  local DISK_ID=$1
  local DISK_DEV=$2
  local DISK_INDEX=$3
  local DISK_ADDRESS=$4

  [ -z "${DISK_DEV}" ] && return 0
  [ ! -b "${DISK_DEV}" ] && error "Device ${DISK_DEV} cannot be found! Please add it to the 'devices' section of your compose file." && exit 55

  DISK_OPTS="${DISK_OPTS} \
    -device virtio-scsi-pci,id=hw-${DISK_ID},bus=pcie.0,addr=${DISK_ADDRESS} \
    -drive file=${DISK_DEV},if=none,id=drive-${DISK_ID},format=raw,cache=${DISK_CACHE},aio=${DISK_IO},discard=${DISK_DISCARD},detect-zeroes=on \
    -device scsi-hd,bus=hw-${DISK_ID}.0,channel=0,scsi-id=0,lun=0,drive=drive-${DISK_ID},id=${DISK_ID},rotation_rate=${DISK_ROTATION},bootindex=${DISK_INDEX}"

  return 0
}

: ${DEVICE:=''}        # Docker variable to passthrough a block device, like /dev/vdc1.
: ${DEVICE2:=''}
: ${DEVICE3:=''}
: ${DEVICE4:=''}
: ${DEVICE5:=''}
: ${DEVICE6:=''}

addDevice "userdata7" "${DEVICE}" "7" "0x6"
addDevice "userdata8" "${DEVICE2}" "8" "0x7"
addDevice "userdata9" "${DEVICE3}" "9" "0x8"
addDevice "userdata4" "${DEVICE4}" "4" "0xd"
addDevice "userdata5" "${DEVICE5}" "5" "0xe"
addDevice "userdata6" "${DEVICE6}" "6" "0xf"

return 0
