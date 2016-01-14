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

# This test tries to read a value from Thermo3 Click and
# lights up an amount of segments on BarGraph's Display depending on
# the value.
# Assumed setup:
# BarGraph Click sitting in mikroBUS 1
# Thermo3 Click sitting in mikroBUS 2
#
# Input argument specifies base temperature. For example if actual temperature
# is 26 and specified base is 20, then 6 display segments will be lit up.

LOG_LEVEL=1
TRIALS=1

MARGIN_BOT=20
SEGMENTS=10

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-c	Number of trials, default 1, and pass -c 0 for continuous mode
-t	Base temperature, default 20
-v	Verbose
-V	Show package version

EOF
}

while getopts "c:t:vVh" opt; do
	case $opt in
		c)
			TRIALS=$OPTARG;;
		t)
			MARGIN_BOT=$OPTARG;;
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

source click_common.sh
redirect_output_and_error $LOG_LEVEL

echo -e "\n**************************  CLICK THERMO3 + BARGRAPH combined test **************************\n" >&3

if [ -z "$MARGIN_BOT" ]
then
    echo -e "Please provide base temperature in celsius, for example 20" >&3
    exit 1
fi

echo -e "base temperature: $MARGIN_BOT\n"

enable_i2c_driver
enable_pwm 1

read_and_update_bargraph()
{
	VAL=`./test_click_read_thermo3 -m 2`
	if [ $? -ne 0 ];then
		return 1
	fi

	echo -e "measured temperature: $VAL\n"
	# drop fraction
	VAL=${VAL%.*}

	MARGIN_TOP=$((MARGIN_BOT+SEGMENTS))
	if [ "$VAL" -ge "$MARGIN_TOP" ]; then ACTIVE=10
	elif [ "$VAL" -le "$MARGIN_BOT" ]; then ACTIVE=0
	else ACTIVE=$((VAL - MARGIN_BOT))
	fi

	./test_click_write_bargraph -m 1 -s "$(( (1<<ACTIVE) - 1 ))"
	if [ $? -ne 0 ];then
		return 1
	fi
}

if [ $TRIALS -eq 0 ];then
	echo -e "Running test continuously\n" >&3
	PASS=0
	FAIL=0
	while true
	do
		read_and_update_bargraph
		if [ $? -eq 0 ];then
			PASS=$((PASS + 1))
		else
			FAIL=$((FAIL + 1))
		fi
		update_test_status "thermo3_bargraph" 2 $PASS $FAIL
		sleep 1
	done
else
	echo -e "Running test for $TRIALS trials\n" >&3
	for j in $(seq 1 $TRIALS)
	do
		read_and_update_bargraph
		echo -e "Bargraph updated\n" >&3
		sleep 1
	done

	echo -e "Are there $ACTIVE active segments?\n" >&3
	show_result_based_on_switch_pressed
fi
