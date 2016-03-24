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

if [ $LOOPS -eq 0 ];then
	echo -e "Play audio continuously on $PCM_DEVICE\n" >&3
	PASS=0
	FAIL=0
	while true
	do
		speaker-test -D $PCM_DEVICE -F S32_LE -c 2 -t sine -l 1
		if [ $? -eq 0 ];then
			PASS=$((PASS + 1))
		else
			FAIL=$((FAIL + 1))
		fi
		update_test_status "audio" 2 $PASS $FAIL
	done
else
	echo -e "Play audio for $LOOPS loops on $PCM_DEVICE\n" >&3
	speaker-test -D $PCM_DEVICE -F S32_LE -c 2 -t sine -l $LOOPS
	if [ $WAIT_FOR_KEY_PRESS = "true" ];then
		echo -e "\nDid you hear the sine wave audio on left and right channels?\n" >&3
		show_result_based_on_switch_pressed
	fi
fi
