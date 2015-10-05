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

# can be used for getting state of GPIO only if it can be exported from user space
# ensure that MFIO number is correct

LOG_LEVEL=1
source common.sh
redirect_output_and_error $LOG_LEVEL

Usage() {
	echo -e "Usage: Give argument as MFIO number e.g. ./test_get_pin.sh 76\n"  >&3
}

if [ "$#" -lt 1 ];then
	Usage
	exit 1
fi

MFIO=$1

# check if the gpio has already been exported
{
	ls /sys/class/gpio/gpio$MFIO
}>&4

if [ $? -ne 0 ];then
	{
		echo $MFIO > /sys/class/gpio/export
	}>&3
	# check for any error, some gpio cannot be exported
	if [ $? -ne 0 ];then
		exit 1
	fi
fi
{
	# set pin direction as input
	DIRECTION=`cat /sys/class/gpio/gpio$MFIO/direction`
	if [ "$DIRECTION" != "in" ]; then
		echo in > /sys/class/gpio/gpio$MFIO/direction
	fi

	#get value
	cat /sys/class/gpio/gpio$MFIO/value
}>&3

