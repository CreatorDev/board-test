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

# This script will record and play audio input from headphone for 30 seconds.

LOG_LEVEL=1
WAIT_FOR_KEY_PRESS=false
RECORD_PLAY_TIME=30
SAMPLE_FORMAT=S32_LE
SAMPLE_RATE=48000
CHANNELS=2

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-i	PCM input device name e.g. -i mic
-o	PCM output device name e.g. -o hw:0,2
-w	Wait for user input on PASS/FAIL
-t	Seconds to record and play, default 30 secs
-v	Verbose
-V	Show package version

EOF
}

while getopts "i:o:t:wvVh" opt; do
	case $opt in
		i)
			PCM_INPUT_DEVICE=$OPTARG;;
		o)
			PCM_OUTPUT_DEVICE=$OPTARG;;
		t)
			RECORD_PLAY_TIME=$OPTARG;;
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

if [[ -z $PCM_INPUT_DEVICE ]];then
	usage
	exit 1
fi

if [[ -z $PCM_OUTPUT_DEVICE ]];then
	usage
	exit 1
fi

redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* Audio Mic test ************************************\n" >&3

echo -e "Enable ADC Power \n" >&3
ADC_POWER_GPIO=511

sh test_set_pin.sh $ADC_POWER_GPIO 1
if [ $? -ne 0 ];then
	exit 1
fi

arecord -f $SAMPLE_FORMAT -c $CHANNELS -r $SAMPLE_RATE -D $PCM_INPUT_DEVICE | \
aplay -f $SAMPLE_FORMAT -r $SAMPLE_RATE -D $PCM_OUTPUT_DEVICE -c $CHANNELS -d $RECORD_PLAY_TIME

if [ $WAIT_FOR_KEY_PRESS == "true" ];then
	# Waiting for user input is currently only for marduk
	echo -e "\nDid you hear the audio in loop back?\n" >&3
	show_result_based_on_switch_pressed
fi
