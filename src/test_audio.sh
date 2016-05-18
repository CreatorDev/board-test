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

# This script will play sine wave on left and right channels.

. /usr/lib/board_test_common.sh

LOOPS=2
WAIT_FOR_KEY_PRESS=false
PASS=0
FAIL=0

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-c  <arg>  Number of loops to play, default 2, and pass -c 0 for continuous mode
-d  <arg>  PCM device name e.g. -d hw:0,2
-w         Wait for user input on PASS/FAIL
-v         Verbose
-V         Show package version
"

while getopts "d:c:wvVh" opt; do
	case $opt in
		d)
			PCM_DEVICE=$OPTARG
			;;
		c)
			LOOPS=$OPTARG
			;;
		w)
			WAIT_FOR_KEY_PRESS=true
			;;
		v)
			LOG_LEVEL=$DEBUG
			;;
		V)
			echo "version = "$(cat $BOARD_TEST_PATH/version)
			exit $SUCCESS
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

if [ -z $PCM_DEVICE ]; then
	LOG_ERROR "${USAGE}"
	exit $FAILURE
fi


LOG_INFO "\n******************************* Audio test ************************************\n"

if [ $LOOPS -eq 0 ];then
	LOG_INFO "Play audio continuously on $PCM_DEVICE\n"
	while true
	do
		speaker-test -D $PCM_DEVICE -F S32_LE -c 2 -t sine -l 1
		if [ $? -eq $SUCCESS ];then
			PASS=$((PASS + 1))
		else
			FAIL=$((FAIL + 1))
		fi
		update_test_status "audio" 2 $PASS $FAIL
	done
else
	LOG_INFO "Play audio for $LOOPS loops on $PCM_DEVICE\n"
	speaker-test -D $PCM_DEVICE -F S32_LE -c 2 -t sine -l $LOOPS
	if [ $WAIT_FOR_KEY_PRESS = "true" ];then
		# Waiting for user input is currently only for marduk
		QUESTION "Did you hear the sine wave audio on left and right channels?\n"
		show_result_based_on_switch_pressed_and_exit
	fi
fi
