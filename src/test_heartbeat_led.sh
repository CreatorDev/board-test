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


# This test will blink the Heartbeat LED on the board

. /usr/lib/board_test_common.sh

BLINK_TIME=10
PASS=0
FAIL=0

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-t  <arg>  Number of seconds to blink heartbeat led, default 10, and pass -t 0 for continuous mode
-v         Verbose
-V         Show package version
"

while getopts "t:vVh" opt; do
	case $opt in
		t)
			BLINK_TIME=$OPTARG
			;;
		v)
			LOG_LEVEL=2
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

set_state()
{
	echo $1 > /sys/class/leds/marduk:red:heartbeat/trigger
}

restore_and_exit()
{
	set_state $1
	reset_color
	exit $FAILURE
}

load_driver()
{
	lsmod | grep $1
	if [ $? -ne $SUCCESS ]; then
		modprobe $1
		if [ $(lsmod | grep $1) -ne $SUCCESS ]; then
			LOG_ERROR "Failed to load driver ${1}\n"
			exit $FAILURE
		fi
	fi
}

# Get previous state
TRIGGER_STATES=$(cat /sys/class/leds/marduk:red:heartbeat/trigger)
PREVIOUS_STATE=$(echo $TRIGGER_STATES | cut -d "[" -f2 | cut -d "]" -f1)

trap 'restore_and_exit $PREVIOUS_STATE' INT


LOG_INFO "\n**************************  HEARTBEAT LED test **************************\n"

load_driver leds_gpio
load_driver ledtrig_heartbeat

if [ $BLINK_TIME -eq 0 ]; then
	LOG_INFO "Blink heartbeat led continuously\n"
else
	LOG_INFO "Blink heartbeat led for up to $BLINK_TIME seconds\n"
fi

set_state "heartbeat"

if [ $BLINK_TIME -ne 0 ]; then
	local RET_STATUS=0
	QUESTION "Does Heartbeat LED blink?\n"
	LOG_INFO "Press switch 1 for pass or switch 2 for fail \n"
	$BOARD_TEST_PATH/test_switch -w -t $BLINK_TIME
	case $? in
		1)
			LOG_INFO "PASS"
			RET_STATUS=0
			;;
		2)
			LOG_ERROR "FAIL"
			RET_STATUS=1
			;;
		254)
			LOG_ERROR "FAIL (no key pressed within timeout)"
			RET_STATUS=254
			;;
		255)
			LOG_ERROR "FAIL (some error in reading switches)"
			RET_STATUS=255
			;;
	esac
	set_state $PREVIOUS_STATE
	exit $RET_STATUS
else
	while true
	do
		sleep 1

		if [ $(cat /sys/class/leds/marduk:red:heartbeat/trigger | grep "\\[heartbeat\\]" -c) -eq 0 ]; then
			FAIL=$((FAIL + 1))
		else
			PASS=$((PASS + 1))
		fi
		update_test_status "heartbeat_led" 2 $PASS $FAIL
	done
fi
