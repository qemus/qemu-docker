#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${DISK_IO:='native'}    # I/O Mode, can be set to 'native', 'threads' or 'io_turing'
: ${DISK_CACHE:='none'}   # Caching mode, can be set to 'writeback' for better performance
: ${DISK_DISCARD:='on'}   # Controls whether unmap (TRIM) commands are passed to the host.
: ${DISK_ROTATION:='1'}   # Rotation rate, set to 1 for SSD storage and increase for HDD
: ${DISK_FMT:='raw'}      # Disk file format, "raw" by default for backwards compatibility

DISK_OPTS=""
BOOT="$STORAGE/boot.img"

if [ -f "$BOOT" ]; then
  DISK_OPTS="${DISK_OPTS} \
    -device virtio-scsi-pci,id=scsi0 \
    -drive id=cdrom0,if=none,format=raw,readonly=on,file=${BOOT} \
    -device scsi-cd,bus=scsi0.0,drive=cdrom0,bootindex=10"
fi

getSize() {
  local DISK_FILE=$1

  qemu-img info "${DISK_FILE}" -f "${DISK_FMT}" | grep '^virtual size: ' | sed 's/.*(\(.*\) bytes)/\1/'
}

doResize() {
  local GB
  local REQ
  local SPACE
  local SPACE_GB
  local DISK_FILE=$1
  local CUR_SIZE=$2
  local DATA_SIZE=$3
  local DISK_SPACE=$4
  local DISK_DESC=$5
  local DISK_FMT=$6

  GB=$(( (CUR_SIZE + 1073741823)/1073741824 ))
  info "Resizing ${DISK_DESC} from ${GB}G to ${DISK_SPACE} .."

  case "${DISK_FMT,,}" in
    raw)
      if [[ "${ALLOCATE}" == [Nn]* ]]; then

        # Resize file by changing its length
        if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
          error "Could not resize ${DISK_DESC} file (${DISK_FILE}) to ${DISK_SPACE} .." && exit 85
        fi

      else

        REQ=$((DATA_SIZE-CUR_SIZE))

        # Check free diskspace
        SPACE=$(df --output=avail -B 1 "${DIR}" | tail -n 1)
        SPACE_GB=$(( (SPACE + 1073741823)/1073741824 ))

        if (( REQ > SPACE )); then
          error "Not enough free space to resize ${DISK_DESC} to ${DISK_SPACE} in ${DIR}, it has only ${SPACE_GB} GB available.."
          error "Specify a smaller ${DISK_DESC^^}_SIZE or disable preallocation with ALLOCATE=N." && exit 84
        fi

        # Resize file by allocating more space
        if ! fallocate -l "${DISK_SPACE}" "${DISK_FILE}"; then
          if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
            error "Could not resize ${DISK_DESC} file (${DISK_FILE}) to ${DISK_SPACE}" && exit 85
          fi
        fi

      fi
      ;;
    qcow2)
      if ! qemu-img resize "${DISK_FILE}" "${DISK_SPACE}" ; then
        error "Could not resize ${DISK_DESC} file (${DISK_FILE}) to ${DISK_SPACE}" && exit 85
      fi
      ;;
  esac
}

createDisk() {
  local GB
  local SPACE
  local SPACE_GB
  local DISK_FILE=$1
  local DISK_SPACE=$2
  local DISK_DESC=$3
  local DISK_FMT=$4

  case "${DISK_FMT,,}" in
    raw)
      if [[ "${ALLOCATE}" == [Nn]* ]]; then

        # Create an empty file
        if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
          rm -f "${DISK_FILE}"
          error "Could not create a ${DISK_SPACE} file for ${DISK_DESC} (${DISK_FILE})" && exit 87
        fi

      else

        # Check free diskspace
        SPACE=$(df --output=avail -B 1 "${DIR}" | tail -n 1)
        SPACE_GB=$(( (SPACE + 1073741823)/1073741824 ))

        if (( DATA_SIZE > SPACE )); then
          error "Not enough free space to create ${DISK_DESC} of ${DISK_SPACE} in ${DIR}, it has only ${SPACE_GB} GB available.."
          error "Specify a smaller ${DISK_DESC^^}_SIZE or disable preallocation with ALLOCATE=N." && exit 86
        fi

        # Create an empty file
        if ! fallocate -l "${DISK_SPACE}" "${DISK_FILE}"; then
          if ! truncate -s "${DISK_SPACE}" "${DISK_FILE}"; then
            rm -f "${DISK_FILE}"
            error "Could not create a ${DISK_SPACE} file for ${DISK_DESC} (${DISK_FILE})" && exit 87
          fi
        fi

      fi
      ;;
    qcow2)
      if ! qemu-img create -f "$DISK_FMT" -- "${DISK_FILE}" "${DISK_SPACE}" ; then
        error "Could not create a ${DISK_SPACE} byte ${DISK_FMT} file for ${DISK_DESC} (${DISK_FILE})" && exit 89
      fi
      ;;
  esac
}

addDisk () {

  local DIR
  local CUR_SIZE
  local DATA_SIZE
  local DISK_ID=$1
  local DISK_FILE=$2
  local DISK_DESC=$3
  local DISK_SPACE=$4
  local DISK_INDEX=$5
  local DISK_ADDRESS=$6
  local DISK_FMT=$7

  DIR=$(dirname "${DISK_FILE}")
  [ ! -d "${DIR}" ] && return 0

  [ -z "$DISK_SPACE" ] && DISK_SPACE="16G"
  DISK_SPACE=$(echo "${DISK_SPACE}" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
  DATA_SIZE=$(numfmt --from=iec "${DISK_SPACE}")

  if [ -f "${DISK_FILE}" ]; then
    CUR_SIZE=$(getSize "${DISK_FILE}")

    if [ "$DATA_SIZE" -gt "$CUR_SIZE" ]; then
      doResize "${DISK_FILE}" "${CUR_SIZE}" "${DATA_SIZE}" "${DISK_SPACE}" "${DISK_DESC}" "${DISK_FMT}" || exit $?
    fi
  else
    createDisk "${DISK_FILE}" "${DISK_SPACE}" "${DISK_DESC}" "${DISK_FMT}" || exit $?
  fi

  DISK_OPTS="${DISK_OPTS} \
    -device virtio-scsi-pci,id=hw-${DISK_ID},bus=pcie.0,addr=${DISK_ADDRESS} \
    -drive file=${DISK_FILE},if=none,id=drive-${DISK_ID},format=${DISK_FMT},cache=${DISK_CACHE},aio=${DISK_IO},discard=${DISK_DISCARD},detect-zeroes=on \
    -device scsi-hd,bus=hw-${DISK_ID}.0,channel=0,scsi-id=0,lun=0,drive=drive-${DISK_ID},id=${DISK_ID},rotation_rate=${DISK_ROTATION},bootindex=${DISK_INDEX}"

  return 0
}

# Get file format extension
case "${DISK_FMT,,}" in
  qcow2)
    DISK_EXT="qcow2"
    ;;
  raw)
    DISK_EXT="img"
    ;;
  *)
    error "Unrecognized disk format ${DISK_FMT}" && exit 88
    ;;
esac

DISK1_FILE="${STORAGE}/data.${DISK_EXT}"
DISK2_FILE="/storage2/data2.${DISK_EXT}"
DISK3_FILE="/storage3/data3.${DISK_EXT}"
DISK4_FILE="/storage4/data4.${DISK_EXT}"
DISK5_FILE="/storage5/data5.${DISK_EXT}"
DISK6_FILE="/storage6/data6.${DISK_EXT}"

: ${DISK2_SIZE:=''}
: ${DISK3_SIZE:=''}
: ${DISK4_SIZE:=''}
: ${DISK5_SIZE:=''}
: ${DISK6_SIZE:=''}

addDisk "userdata" "${DISK1_FILE}" "disk" "${DISK_SIZE}" "1" "0xa" "${DISK_FMT}"
addDisk "userdata2" "${DISK2_FILE}" "disk2" "${DISK2_SIZE}" "2" "0xb" "${DISK_FMT}"
addDisk "userdata3" "${DISK3_FILE}" "disk3" "${DISK3_SIZE}" "3" "0xc" "${DISK_FMT}"
addDisk "userdata4" "${DISK4_FILE}" "disk4" "${DISK4_SIZE}" "4" "0xd" "${DISK_FMT}"
addDisk "userdata5" "${DISK5_FILE}" "disk5" "${DISK5_SIZE}" "5" "0xe" "${DISK_FMT}"
addDisk "userdata6" "${DISK6_FILE}" "disk6" "${DISK6_SIZE}" "6" "0xf" "${DISK_FMT}"

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
