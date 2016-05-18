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

. /usr/lib/board_test_common.sh

WAIT_FOR_KEY_PRESS=false
RECORD_PLAY_TIME=30
SAMPLE_FORMAT=S32_LE
SAMPLE_RATE=48000
CHANNELS=2
CONTINUOUS=false
ADC_POWER_GPIO=511

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-i  <arg>  PCM input device name e.g. -i mic
-o  <arg>  PCM output device name e.g. -o hw:0,2
-w         Wait for user input on PASS/FAIL
-c  <arg>  Seconds to record and play, default 30 secs, pass 0 for continuous mode
-v         Verbose
-V         Show package version
"

while getopts "i:o:c:wvVh" opt; do
	case $opt in
		i)
			PCM_INPUT_DEVICE=$OPTARG
			;;
		o)
			PCM_OUTPUT_DEVICE=$OPTARG
			;;
		c)
			RECORD_PLAY_TIME=$OPTARG
			;;
		v)
			LOG_LEVEL=$DEBUG
			;;
		V)
			echo "version = "$(cat $BOARD_TEST_PATH/version)
			exit $SUCCESS
			;;
		w)
			WAIT_FOR_KEY_PRESS=true
			;;
		h)
			echo "${USAGE}"
			exit $SUCCESS
			;;
		\?)
			echo "${USAGE}"
			exit $FAILURE
			;;
	esac
done

redirect_output_and_error $LOG_LEVEL

if [ -z $PCM_INPUT_DEVICE ]; then
	LOG_ERROR "${USAGE}"
	exit $FAILURE
fi

if [ -z $PCM_OUTPUT_DEVICE ]; then
	LOG_ERROR "${USAGE}"
	exit $FAILURE
fi

if [ $RECORD_PLAY_TIME -eq 0 ]; then
	CONTINUOUS=true
	RECORD_PLAY_TIME=30
fi

audio_loopback()
{
	arecord -f $SAMPLE_FORMAT -c $CHANNELS -r $SAMPLE_RATE -D $PCM_INPUT_DEVICE | \
	aplay -f $SAMPLE_FORMAT -r $SAMPLE_RATE -D $PCM_OUTPUT_DEVICE -c $CHANNELS -d $RECORD_PLAY_TIME
}


LOG_INFO "\n******************************* Audio Mic test ************************************\n"

LOG_INFO "Enable ADC Power\n"

$BOARD_TEST_PATH/test_set_pin.sh $ADC_POWER_GPIO 1
if [ $? -ne $SUCCESS ]; then
	LOG_ERROR "Failed to set ADC power gpio\n"
	exit $FAILURE
fi

# Do audio loopback at least once
audio_loopback

if [ $CONTINUOUS == true ]; then
	while true
	do
		audio_loopback
	done
fi

if [ $WAIT_FOR_KEY_PRESS == "true" ]; then
	# Waiting for user input is currently only for marduk
	QUESTION "Did you hear the audio in loop back?\n"
	show_result_based_on_switch_pressed_and_exit
fi
