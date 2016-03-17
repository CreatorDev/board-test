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

run_test()
{
	# sc16is7xx has 8 GPIO's, they get added from 504 to 511, 511 is connected to click power enable
	# while others are connected to LED
	echo -e "Enable Click Power \n"
	CLICK_POWER_GPIO=511

	sh test_set_pin.sh $CLICK_POWER_GPIO 1

	echo -e "Blinking all Led's \n"

	for i in 504 505 506 507 508 509 510
	do
		sh test_set_pin.sh $i 1
		usleep $BLINK_DELAY_USEC
		sh test_set_pin.sh $i 0
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

