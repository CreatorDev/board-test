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

# This test will blink the Heartbeat LED on the board

LOG_LEVEL=1
BLINK_DELAY_USEC=50000
BLINK_COUNT=10

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-c	Number of blink counts, default 10, and pass -c 0 for continuous mode
-d	Blink delay in milliseconds, default 50 milliseconds
-v	Verbose
-V	Show package version

EOF
}

while getopts "d:c:vVh" opt; do
	case $opt in
		c)
			BLINK_COUNT=$OPTARG;;
		d)
			BLINK_DELAY_USEC=$(($OPTARG * 1000));;
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

echo -e "\n**************************  HEARTBEAT LED test **************************\n" >&3

HEARTBEAT_LED=76

blink_led()
{
	sh test_set_pin.sh $HEARTBEAT_LED 0
	if [ $? -ne 0 ];then
		return 1
	fi
	usleep $BLINK_DELAY_USEC

	sh test_set_pin.sh $HEARTBEAT_LED 1
	if [ $? -ne 0 ];then
		return 1
	fi
	usleep $BLINK_DELAY_USEC

	sh test_set_pin.sh $HEARTBEAT_LED 0
	if [ $? -ne 0 ];then
		return 1
	fi
	usleep $BLINK_DELAY_USEC
}

if [ $BLINK_COUNT -eq 0 ];then
	echo -e "Blink heartbeat led continuously\n" >&3
	PASS=0
	FAIL=0
	while true
	do
		blink_led
		if [ $? -eq 0 ];then
			PASS=$((PASS + 1))
		else
			FAIL=$((FAIL + 1))
		fi
		update_test_status "heartbeat" 2 $PASS $FAIL
	done
else
	echo -e "Blink heartbeat led for $BLINK_COUNT counts\n" >&3
	for j in $(seq 1 $BLINK_COUNT)
	do
		blink_led
	done

	echo -e "\nDid Heartbeat LED blink?\n" >&3
	show_result_based_on_switch_pressed
fi
