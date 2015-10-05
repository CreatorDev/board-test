#
# Copyright 2015 by Imagination Technologies Limited and/or its affiliated group companies.
#
# All rights reserved.  No part of this software, either
# material or conceptual may be copied or distributed,
# transmitted, transcribed, stored in a retrieval system
# or translated into any human or computer language in any
# form by any means, electronic, mechanical, manual or
# other-wise, or disclosed to the third parties without the
# express written permission of Imagination Technologies
# Limited, Home Park Estate, Kings Langley, Hertfordshire,
# WD4 8LZ, U.K.

# This script will test sdcard by doing read write to it
# And it will work only if sdcard has fat filesystem

LOG_LEVEL=1

source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* SD card test **********************************\n" >&3

COUNT=`ls /dev | grep mmcblk0p -c`
TOTAL_MMC_DEVS=$COUNT

if [ $COUNT -ne 0 ];then

	echo "$COUNT mmc partitions found"

	while [ $COUNT -gt 0 ]
	do
		COUNT=`expr $COUNT - 1`
		NUM=$(($TOTAL_MMC_DEVS-$COUNT))
		MMC_DEVICE=`ls /dev/ | grep mmcblk0p | head -n $NUM | tail -n 1`
		MOUNT_DIR=/mnt/$MMC_DEVICE

		if mountpoint -q -- $MOUNT_DIR;then
			umount $MOUNT_DIR
			rm -rf $MOUNT_DIR
		fi

		mkdir -p $MOUNT_DIR		&&\
		mount -t vfat /dev/$MMC_DEVICE $MOUNT_DIR	&&\
		dd if=/dev/zero of=/tmp/temp0.img bs=1k count=1024		&&\
		dd if=/tmp/temp0.img of=$MOUNT_DIR/temp1.img	&&\
		cmp /tmp/temp0.img $MOUNT_DIR/temp1.img && COUNT=0
		{
			[ $? == 0 ] && echo "PASS" || (echo "FAIL - partition $MMC_DEVICE"; if [ $COUNT = 1 ]; then exit 1; fi)
		} >&3

		rm /tmp/temp0.img $MOUNT_DIR/temp1.img >&4
	done

else
	echo "FAIL - mmc partitions not found" >&3
	exit 1
fi

