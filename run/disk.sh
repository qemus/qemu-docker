#!/usr/bin/env bash
set -Eeuo pipefail

# Docker environment variables

: ${DISK_IO:='native'}    # I/O Mode, can be set to 'native', 'threads' or 'io_turing'
: ${DISK_CACHE:='none'}   # Caching mode, can be set to 'writeback' for better performance
: ${DISK_DISCARD:='on'}   # Controls whether unmap (TRIM) commands are passed to the host.
: ${DISK_ROTATION:='1'}   # Rotation rate, set to 1 for SSD storage and increase for HDD

BOOT="$STORAGE/boot.img"
[ ! -f "$BOOT" ] && echo "ERROR: Boot image does not exist ($BOOT)" && exit 81

DATA="${STORAGE}/data.img"
DISK_SIZE=$(echo "${DISK_SIZE}" | sed 's/MB/M/g;s/GB/G/g;s/TB/T/g')
DATA_SIZE=$(numfmt --from=iec "${DISK_SIZE}")

if [ -f "${DATA}" ]; then

  OLD_SIZE=$(stat -c%s "${DATA}")

  if [ "$DATA_SIZE" -gt "$OLD_SIZE" ]; then

    info "Resizing data disk from $OLD_SIZE to $DATA_SIZE bytes.."

    if [[ "${ALLOCATE}" == [Nn]* ]]; then

      # Resize file by changing its length
      if ! truncate -s "${DATA_SIZE}" "${DATA}"; then
        error "Could not resize the file for the data disk." && exit 85
      fi

    else

      REQ=$((DATA_SIZE-OLD_SIZE))

      # Check free diskspace
      SPACE=$(df --output=avail -B 1 "${STORAGE}" | tail -n 1)

      if (( REQ > SPACE )); then
        error "Not enough free space to resize data disk to ${DISK_SIZE}."
        error "Specify a smaller size or disable preallocation with ALLOCATE=N." && exit 84
      fi

      # Resize file by allocating more space
      if ! fallocate -l "${DATA_SIZE}" "${DATA}"; then
        if ! truncate -s "${DATA_SIZE}" "${DATA}"; then
          error "Could not resize the file for the data disk." && exit 85
        fi
      fi

      if [[ "${ALLOCATE}" == [Zz]* ]]; then

        GB=$(( (REQ + 1073741823)/1073741824 ))

        info "Preallocating ${GB} GB of diskspace, please wait..."
        dd if=/dev/urandom of="${DATA}" seek="${OLD_SIZE}" count="${REQ}" bs=1M iflag=count_bytes oflag=seek_bytes status=none

      fi
    fi
  fi

  if [ "$DATA_SIZE" -lt "$OLD_SIZE" ]; then

    info "Shrinking existing disks is not supported yet!"
    info "Creating backup of old drive in storage folder..."

    mv -f "${DATA}" "${DATA}.bak"

  fi
fi

if [ ! -f "${DATA}" ]; then

  if [[ "${ALLOCATE}" == [Nn]* ]]; then

    # Create an empty file
    if ! truncate -s "${DATA_SIZE}" "${DATA}"; then
      rm -f "${DATA}"
      error "Could not create a file for the data disk." && exit 87
    fi

  else

    # Check free diskspace
    SPACE=$(df --output=avail -B 1 "${STORAGE}" | tail -n 1)

    if (( DATA_SIZE > SPACE )); then
      error "Not enough free space to create a data disk of ${DISK_SIZE}."
      error "Specify a smaller size or disable preallocation with ALLOCATE=N." && exit 86
    fi

    # Create an empty file
    if ! fallocate -l "${DATA_SIZE}" "${DATA}"; then
      if ! truncate -s "${DATA_SIZE}" "${DATA}"; then
        rm -f "${DATA}"
        error "Could not create a file for the data disk." && exit 87
      fi
    fi

    if [[ "${ALLOCATE}" == [Zz]* ]]; then

      info "Preallocating ${DISK_SIZE} of diskspace, please wait..."
      dd if=/dev/urandom of="${DATA}" count="${DATA_SIZE}" bs=1M iflag=count_bytes status=none

    fi
  fi

  # Check if file exists
  if [ ! -f "${DATA}" ]; then
    error "Data disk does not exist ($DATA)" && exit 88
  fi

fi

# Check the filesize
SIZE=$(stat -c%s "${DATA}")

if [[ SIZE -ne DATA_SIZE ]]; then
  error "Virtual disk has the wrong size: ${SIZE}" && exit 89
fi

DISK_OPTS="\
    -drive id=cdrom0,if=none,format=raw,readonly=on,file=${BOOT} \
    -device virtio-scsi-pci,id=scsi0 \
    -device scsi-cd,bus=scsi0.0,drive=cdrom0 \
    -device virtio-scsi-pci,id=hw-userdata,bus=pcie.0,addr=0xa \
    -drive file=${DATA},if=none,id=drive-userdata,format=raw,cache=${DISK_CACHE},aio=${DISK_IO},discard=${DISK_DISCARD},detect-zeroes=on \
    -device scsi-hd,bus=hw-userdata.0,channel=0,scsi-id=0,lun=0,drive=drive-userdata,id=userdata0,rotation_rate=${DISK_ROTATION},bootindex=1"
