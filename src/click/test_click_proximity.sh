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

# This test reads proximity and checks if the value in the expected range.
# By default, the click board is assumed sitting in mikroBUS 1.

. /usr/lib/board_test_click_common.sh

COUNTER=1
MIKROBUS=1
PASS=0
FAIL=0
# Offset (when distance is greater than around ~15 cm)
MIN_VALUE=2120
# Max value when literally touching the sensor
MAX_VALUE=52000

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-c  <arg>  Number of times to run this test (0 means forever, default 1)
-m  <arg>  mikroBUS number (1 or 2, default 1)
-v         Verbose
-V         Show package version
"

while getopts "c:m:vVh" opt; do
	case $opt in
		c)
			COUNTER=$OPTARG
			;;
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

run_test()
{
	# Enable periodic measurements
	$BOARD_TEST_PATH/test_click_access_proximity -m $MIKROBUS -a e
	if [ $? -ne $SUCCESS ]; then
		return $FAILURE
	fi

	# Make sure that a measurement has finished
	sleep 1

	# Read the value
	VAL=$($BOARD_TEST_PATH/test_click_access_proximity -m $MIKROBUS -a p)
	if [ $? -ne $SUCCESS ]; then
		return $FAILURE
	fi

	# Disable measurements
	$BOARD_TEST_PATH/test_click_access_proximity -m $MIKROBUS -a d
	if [ $? -ne $SUCCESS ]; then
		return $FAILURE
	fi

	return $SUCCESS
}

update_pass_fail_var()
{
	if [ $? -eq $SUCCESS -a $VAL -ge $MIN_VALUE -a $VAL -le $MAX_VALUE ]; then
		PASS=$((PASS + 1))
	else
		FAIL=$((FAIL + 1))
	fi
}


LOG_INFO "\n**************************  CLICK PROXIMITY test **************************\n"

enable_i2c_driver

# Continuous test mode
if [ $COUNTER -eq 0 ]; then
	LOG_INFO "Testing click proximity sensor continuously\n"
	while true; do
		run_test
		update_pass_fail_var
		update_test_status "proximity" 2 $PASS $FAIL
	done
fi

# Call run_test $counter times
while [ $COUNTER -ne 0 ]; do
	PASS=0
	run_test
	update_pass_fail_var

	LOG_INFO "Proximity: $VAL"
	if [ $PASS -ne 0 ]; then
		LOG_INFO "PASS"
	else
		LOG_ERROR "FAIL (value not in expected range)"
	fi
	COUNTER=$((COUNTER - 1))
done
