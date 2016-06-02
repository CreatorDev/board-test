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

# This tests currently display a pattern using the LED driven by the spi-uart chip

. /usr/lib/board_test_common.sh

NB_LEDS=8
TIMEOUT=10
DELAY_USEC=50000
TRIALS=1
CONTINUOUS=false
PASS=0
FAIL=0
PATTERN="11111111"

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-t  <arg>  Timeout in seconds, default 10 seconds
-c  <arg>  Number of times to run test, default 1, and pass -c 0 for continuous mode
-p  <arg>  Pattern to display, e.g. 10101010, default 11111111
"

while getopts "t:c:p:vVh" opt; do
	case $opt in
		t)
			TIMEOUT=$OPTARG
			;;
		c)
			TRIALS=$OPTARG
			;;
		p)
			PATTERN=$OPTARG
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

set_led()
{
	local LED_INDEX=$1
	local VALUE=$2

	if [ $LED_INDEX -eq 8 ]; then
		echo $VALUE > /sys/class/leds/marduk\:red\:heartbeat/brightness
	else
		echo $VALUE > /sys/class/leds/marduk\:red\:user$LED_INDEX/brightness
	fi
}

switch_off_leds()
{
	echo "none" > /sys/class/leds/marduk\:red\:heartbeat/trigger

	for i in $(seq 1 1 $NB_LEDS)
	do
		set_led $i 0
	done
}

check_pin()
{
	PATH="/sys/class/leds/marduk\:red\:user$1/brightness"
	if [ $1 -eq 8 ]; then
		PATH="/sys/class/leds/marduk\:red\:heartbeat/brightness"
	fi

	if [ $(cat $PATH) != "${PATTERN:$(($1-1)):1}" ]; then
		return $FAILURE
	else
		return $SUCCESS
	fi
}

run_test()
{
	switch_off_leds

	LOG_INFO "Displaying pattern on Led's \n"

	for i in $(seq 1 1 $NB_LEDS)
	do
		set_led $i "${PATTERN:$((i-1)):1}"
		usleep $DELAY_USEC
	done

	# Cannot switch button if run from continous-test-marduk script
	if [ $CONTINUOUS = false ]; then
		QUESTION "Did the LED's switch on/off according to pattern $PATTERN ?\n"
		show_result_based_on_switch_pressed $TIMEOUT
		if [ $? -ne $SUCCESS ]; then
			switch_off_leds
			return $FAILURE
		fi
	else
		for i in $(seq 1 1 $NB_LEDS)
		do
			check_pin $i ${PATTERN:$((i-1)):1}
			if [ $? -ne $SUCCESS ]; then
				FAIL=$((FAIL + 1))
				switch_off_leds
				return $FAILURE
			fi
		done
		PASS=$((PASS + 1))
	fi

	switch_off_leds

	return $SUCCESS
}

switch_off_leds_and_exit()
{
	switch_off_leds
	reset_color
	exit $FAILURE
}

# handle Ctrl+c
trap switch_off_leds_and_exit INT

LOG_INFO "\n**************************  SPI-UART LEDS test **************************\n"

# Load driver
if [ $(lsmod | grep leds_gpio -c) -eq 0 ]; then
	modprobe leds_gpio
	if [ $? -ne $SUCCESS ]; then
		LOG_ERROR "Failed to load leds_gpio driver\n"
		exit $FAILURE
	fi
fi

if [ $TRIALS -eq 0 ]; then
	CONTINUOUS=true
fi

while [ "$CONTINUOUS" = true -o $TRIALS -gt 0 ]
do
	run_test
	if [ $? -ne $SUCCESS -a $CONTINUOUS != true ]; then
		exit $FAILURE
	fi

	if [ "$CONTINUOUS" = true ]; then
		update_test_status "spi_uart_leds" 2 $PASS $FAIL
	fi

	TRIALS=$(($TRIALS-1))
	sleep 1
done
