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

# This test checks whether Motion Click triggers an interrupt.

. /usr/lib/board_test_click_common.sh

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-m  <arg>  mikroBUS number (1 or 2)
-v         Verbose
-V         Show package version
"

while getopts "m:vVh" opt; do
	case $opt in
		m)
			MIKROBUS=$OPTARG
			if [ $MIKROBUS -eq 1 ]; then
				GPIO_NUM=21
			elif [ $MIKROBUS -eq 2 ]; then
				GPIO_NUM=24
			else
				echo "${USAGE}"
				exit $FAILURE
			fi
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

if [ -z $MIKROBUS ]; then
	LOG_ERROR "${USAGE}"
	exit $FAILURE
fi


LOG_INFO "\n**************************  CLICK MOTION test **************************\n"

TOP_GPIO_DIR="/sys/class/gpio"
GPIO_DIR="${TOP_GPIO_DIR}/gpio${GPIO_NUM}"

if [ ! -d "$GPIO_DIR" ]; then
	echo $GPIO_NUM > "${TOP_GPIO_DIR}/export"
fi

echo "in" > "${GPIO_DIR}/direction"
echo "rising" > "${GPIO_DIR}/edge"

LOG_INFO "Please move your hand towards the front of the sensor"

$BOARD_TEST_PATH/test_click_wait_gpio -g $GPIO_NUM -t 5
if [ $? -ge 1 ]; then
	LOG_INFO "PASS"
else
	LOG_ERROR "FAIL: no interrupt"
	exit $FAILURE
fi
