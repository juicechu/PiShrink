#!/bin/bash

do_expand_rootfs() {
  PARENT_PART="sdc"
  ROOT_PART="sdc3"

  PART_NUM=${ROOT_PART#$PARENT_PART}
  if [ "$PART_NUM" = "$ROOT_PART" ]; then
    echo "$ROOT_PART is not an SD card. Don't know how to expand"
    return 0
  fi

  # Get the starting offset of the root partition
  PART_START=$(parted /dev/$PARENT_PART -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk /dev/$PARENT_PART <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF

echo "Expanding /dev/$ROOT_PART"
e2fsck -f /dev/$ROOT_PART
resize2fs /dev/$ROOT_PART
echo "Expanded /dev/$ROOT_PART"
exit
}
echo "WARNING: Using backup expand..."
do_expand_rootfs
echo "ERROR: Expanding failed..."
exit 0
