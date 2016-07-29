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

# This test sets bargraph click display's segments.

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
			if [ $MIKROBUS -ne 1 ] && [ $MIKROBUS -ne 2 ]; then
				echo "${USAGE}"
				exit $FAILURE
			fi
			;;
		v)
			LOG_LEVEL=$DEBUG
			;;
		V)
			echo "version = "$(cat $BOARD_TEST_PATH/version)
			exit $SUCESS
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


LOG_INFO "\n**************************  CLICK BARGARPH test **************************\n"

enable_pwm $MIKROBUS

# Run the actual test
$BOARD_TEST_PATH/test_click_write_bargraph -m $MIKROBUS -d

QUESTION "\nDid BarGraph Display's segments light up?\n"
show_result_based_on_switch_pressed_and_exit
