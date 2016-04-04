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

# This tests currently enables click power and blinks the LED driven by the spi-uart chip

LOG_LEVEL=1
BLINK_DELAY_USEC=50000
TRIALS=1
CONTINUOUS=false

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-c	Number of times to run test, default 1, and pass -c 0 for continuous mode
EOF
}

while getopts "c:vVh" opt; do
	case $opt in
		c)
			TRIALS=$OPTARG;;
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

echo -e "\n**************************  SPI-UART chip test **************************\n" >&3

set_led()
{
	echo $2 > /sys/class/leds/marduk\:red\:user$1/brightness
}

run_test()
{
	echo -e "Blinking all Led's \n"

	# Switch off all leds
	for i in 1 2 3 4 5 6 7
	do
		set_led $i 0
	done

	for i in 1 2 3 4 5 6 7
	do
		set_led $i 1
		usleep $BLINK_DELAY_USEC
		set_led $i 0
		usleep $BLINK_DELAY_USEC
	done

	# Cannot switch button if run from continous-test-marduk script
	if [ "$CONTINUOUS" = false ]; then
		echo -e "\nDid all the LED's blink?\n" >&3
		show_result_based_on_switch_pressed
	fi
}

if [ $TRIALS -eq 0 ]; then
	CONTINUOUS=true
fi

while [ "$CONTINUOUS" = true -o $TRIALS -gt 0 ]
do
	run_test
	TRIALS=$(($TRIALS-1))
	sleep 1
done

