#
# Copyright 2016 by Imagination Technologies Limited and/or its affiliated group companies.
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
#
# Can be used to toggle led at a specified frequency.

. /usr/lib/board_test_common.sh

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-i  <arg>  MFIO number
-d  <arg>  Duration of each state in microseconds
-v         Verbose
-V         Show package version
"

while getopts "i:d:vVh" opt; do
	case $opt in
		i)
			PIN_NO=$OPTARG
			;;
		d)
			DURATION=$OPTARG
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

if [ -z $DURATION ] || [ -z $PIN_NO ]; then
	LOG_ERROR "${USAGE}"
	exit $FAILURE
fi


LOG_INFO "\n**************************  Toggle pin test **************************\n"

LOG_INFO "Press Ctrl+C to stop the script\n"

ls /sys/class/gpio/gpio$PIN_NO

if [ $? -ne $SUCCESS ]; then
		LOG_INFO "Enabling pin $PIN_NO..."
		echo $PIN_NO > /sys/class/gpio/export
		usleep 50000

		# Exit if gpio was not successfully enabled
		ls /sys/class/gpio/gpio$PIN_NO
		if [ $? -ne $SUCCESS ]; then
			exit $FAILURE
		fi
fi

# Ensure that selected GPIO is an output
echo out > /sys/class/gpio/gpio$PIN_NO/direction
usleep 50000

while true
do
	echo 1 > /sys/class/gpio/gpio$PIN_NO/value
	usleep $DURATION
	echo 0 > /sys/class/gpio/gpio$PIN_NO/value
	usleep $DURATION
done
