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

# This test tries to read a value from Thermo3 Click and
# reports PASS if the value is in expected range.

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


LOG_INFO "\n**************************  CLICK THERMO3 test **************************\n"

enable_i2c_driver

# Run the actual test
VAL=$($BOARD_TEST_PATH/test_click_read_thermo3 -m $MIKROBUS)
LOG_INFO "temperature: $VAL"

# Convert float to integer and check if in expected range
TEMP=${VAL%.*}
if [ "$TEMP" -ge 5 -a "$TEMP" -le 50 ]; then
	LOG_INFO "\nPASS"
else
	LOG_ERROR "\nFAIL (value not in expected range)"
fi
