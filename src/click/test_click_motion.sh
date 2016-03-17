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

LOG_LEVEL=1

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-m	mikroBUS number (1 or 2)
-v	Verbose
-V	Show package version

EOF
}

while getopts "m:vVh" opt; do
	case $opt in
		m)
			MIKROBUS=$OPTARG
			if [ $MIKROBUS -eq 1 ]; then
				GPIO_NUM=21
			elif [ $MIKROBUS -eq 2 ]; then
				GPIO_NUM=24
			else
				usage
				exit 1
			fi;;
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

if [[ -z $MIKROBUS ]];then
	usage
	exit 1
fi

source click_common.sh
redirect_output_and_error $LOG_LEVEL

echo -e "\n**************************  CLICK MOTION test **************************\n" >&3

TOP_GPIO_DIR="/sys/class/gpio"
GPIO_DIR="${TOP_GPIO_DIR}/gpio${GPIO_NUM}"

if [ ! -d "$GPIO_DIR" ]; then
	echo $GPIO_NUM > "${TOP_GPIO_DIR}/export"
fi

echo "in" > "${GPIO_DIR}/direction"
echo "rising" > "${GPIO_DIR}/edge"

echo "Please move your hand towards the front of the sensor" >&3

./test_click_wait_gpio -g $GPIO_NUM -t 5
RESULT=$?

if [ "$RESULT" -ge 1 ]; then
    echo "PASS" >&3
else
    echo "FAIL: no interrupt" >&3
    exit 1
fi
