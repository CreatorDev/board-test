#!/bin/sh
#
# Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies
# and/or licensors
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to
#    endorse or promote products derived from this software without specific prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
# WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
	echo -e "\nDid you hear the audio in loop back?\n" >&3
	show_result_based_on_switch_pressed
fi
