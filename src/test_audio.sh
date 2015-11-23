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

# This script will play sine wave on left and right channels.

LOG_LEVEL=1
LOOPS=2
WAIT_FOR_KEY_PRESS=false

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-c	Number of loops to play, default 2, and pass -c 0 for continuous mode
-d	PCM device name e.g. -d hw:0,2
-w	wait for user input on PASS/FAIL
-v	Verbose
-V	Show package version

EOF
}

while getopts "d:c:wvVh" opt; do
	case $opt in
		d)
			PCM_DEVICE=$OPTARG;;
		c)
			LOOPS=$OPTARG;;
		v)
			LOG_LEVEL=2;;
		V)
			echo -n "version = "
			cat version
			exit 0;;
		w)
			WAIT_FOR_KEY_PRESS=true;;
		h)
			usage
			exit 0;;
		\?)
			usage
			exit 1;;
	esac
done

if [[ -z $PCM_DEVICE ]];then
	usage
	exit 1
fi

redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* Audio test ************************************\n" >&3

if [ $LOOPS -ne 0 ];then
	echo -e "Play audio for $LOOPS loops on $PCM_DEVICE\n" >&3
else
	echo -e "Play audio continuously on $PCM_DEVICE\n" >&3
fi

speaker-test -D $PCM_DEVICE -F S32_LE -c 2 -t sine -l $LOOPS

if [ $WAIT_FOR_KEY_PRESS = "true" ];then
	# Waiting for user input is currently only for marduk
	echo -e "\nDid you hear the sine wave audio on left and right channels?\n" >&3
	show_result_based_on_switch_pressed
fi
