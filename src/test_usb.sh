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

# This script will test USB by doing read write to it but it will only work when device is booted from USB.

. /usr/lib/board_test_common.sh

TRIALS=1
CONTINUOUS=false
PASS=0
FAIL=0
SRC_TEMP_FILE=/tmp/temp0.img
DST_TEMP_FILE=/data/temp1.img

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-c  <arg>  Number of trials, default 1, and pass -c 0 for continuous mode
-v         Verbose
-V         Show package version
"

while getopts "c:vVh" opt; do
	case $opt in
		c)
			TRIALS=$OPTARG
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

cleanup_and_exit()
{
	# Remove temp files
	rm -f $SRC_TEMP_FILE $DST_TEMP_FILE  >/dev/null
	reset_color
	exit $FAILURE
}

# handle Ctrl+c
trap cleanup_and_exit INT


LOG_INFO "\n******************************* USB test **********************************\n"

# Check whether device is USB booted
grep "root=/dev/sda1" /proc/cmdline
if [ $? -ne $SUCCESS ]; then
	LOG_ERROR "Can't test USB, as device is not USB booted"
	exit $FAILURE
fi

if [ $TRIALS -eq 0 ]; then
	CONTINUOUS=true
	LOG_INFO "Test will run in continuous mode\n"
fi


while [ $CONTINUOUS == true -o $TRIALS -gt 0 ]
do
	check_read_write $SRC_TEMP_FILE $DST_TEMP_FILE
	if [ $? -eq $SUCCESS ]; then
		PASS=$((PASS + 1))
		# Print test status for each trial only for non-continuous mode
		if [ $CONTINUOUS == false ]; then LOG_INFO "PASS"; fi
	else
		FAIL=$((FAIL + 1))
		# Print test status for each trial only for non-continuous mode
		if [ $CONTINUOUS == false ]; then LOG_INFO "FAIL"; fi
	fi

	if [ $CONTINUOUS == true ];then
		update_test_status "usb" 2 $PASS $FAIL
	fi

	# Remove temp files
	rm -f $SRC_TEMP_FILE $DST_TEMP_FILE >/dev/null

	TRIALS=$(($TRIALS-1))
	sleep 1
done
