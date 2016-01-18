#!/bin/sh
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

# This script will test sdcard/eMMC by doing read write to it
# And it will work only if sdcard/eMMC has ext4 filesystem.
# The script will test sdcard by default.

LOG_LEVEL=1
TRIALS=1
CONTINUOUS=false

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-c	Number of trials, default 1, and pass -c 0 for continuous mode
-v	Verbose
-V	Show package version

EOF
}

while getopts "c:vVh" opt; do
	case $opt in
		c)
			TRIALS=$OPTARG;;
		v)
			LOG_LEVEL=2;;
		V)
			echo -n "version = "
			cat version
			exit 0;;
		h)
			usage
			exit 0;;
		\?)
			usage
			exit 1;;
	esac
done

redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* SD card/emmc test **********************************\n" >&3

#Detect storage device on the board
SEARCH_CMD="grep mmcblk0p"
TOTAL_MMC_DEVS=`ls /dev | $SEARCH_CMD -c`
if [ $TOTAL_MMC_DEVS -ne 0 ];then
	echo -e "SD card found on the board" >&3
	TEST_DEVICE=sdcard
else
	SEARCH_CMD="grep mmcblk0 -w"
	TOTAL_MMC_DEVS=`ls /dev | $SEARCH_CMD -c`
	TEST_DEVICE=eMMC
	if [ $TOTAL_MMC_DEVS -ne 0 ];then
		echo -e "eMMC found on the board" >&3
	else
		echo "FAIL - partitions not found" >&3
		exit 1
	fi
fi

create_mountpoints()
{
	COUNT=$1
	while [ $COUNT -gt 0 ]
	do
		COUNT=`expr $COUNT - 1`
		NUM=$(($TOTAL_MMC_DEVS-$COUNT))
		MMC_DEVICE=`ls /dev/ | $SEARCH_CMD | head -n $NUM | tail -n 1`
		MOUNT_DIR=/mnt/$MMC_DEVICE

		if mountpoint -q -- $MOUNT_DIR;then
			umount $MOUNT_DIR
			rm -rf $MOUNT_DIR
		fi

		mkdir -p $MOUNT_DIR
		mkfs.ext4 -F /dev/$MMC_DEVICE
		mount -t ext4 /dev/$MMC_DEVICE $MOUNT_DIR
	done
}

create_mountpoints $TOTAL_MMC_DEVS

#check if we are asked to run continuously
if [ $TRIALS -eq 0 ];then
	CONTINUOUS=true
fi

PASS=0
FAIL=0
while [ $CONTINUOUS == true -o $TRIALS -gt 0 ]
do
	COUNT=$TOTAL_MMC_DEVS
	while [ $COUNT -gt 0 ]
	do
		COUNT=$((COUNT-1))
		NUM=$(($TOTAL_MMC_DEVS-$COUNT))
		MMC_DEVICE=`ls /dev/ | $SEARCH_CMD | head -n $NUM | tail -n 1`
		MOUNT_DIR=/mnt/$MMC_DEVICE

		if mountpoint -q -- $MOUNT_DIR;then
			dd if=/dev/urandom of=/tmp/temp0.img bs=1k count=1024	&&\
			cp /tmp/temp0.img $MOUNT_DIR/temp1.img	&&\
			sync	&&\
			cmp /tmp/temp0.img $MOUNT_DIR/temp1.img
			if [ $? == 0 ]; then
				echo "PASS"
				PASS=$((PASS + 1))
			else
				echo "FAIL - partition $MMC_DEVICE"
				FAIL=$((FAIL + 1))
				if [ $COUNT == 0 ]; then
					exit 1
				fi
			fi
			[ $CONTINUOUS == true ] && update_test_status "$TEST_DEVICE" 2 $PASS $FAIL
			rm /tmp/temp0.img $MOUNT_DIR/temp1.img >&4
		fi
	done
	TRIALS=$(($TRIALS-1))
	sleep 1
done
