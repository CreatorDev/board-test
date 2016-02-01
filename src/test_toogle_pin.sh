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

LOG_LEVEL=1


usage() {
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-i	MFIO number
-d	duration of each state in microseconds
-v	Verbose
-V	Show package version

EOF
}

while getopts "i:d:vVh" opt; do
	case $opt in
        i)
            PIN_NO=$OPTARG;;
		d)
			DURATION=$OPTARG;;
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

if [ -z $DURATION ] || [ -z $PIN_NO ]; then
    usage
    exit 1
fi

source common.sh
redirect_output_and_error $LOG_LEVEL

echo -e "\n**************************  Toggle pin test ************************** \n" >&3
echo -e "Press Ctrl+C to stop the script\n" >&3

ls /sys/class/gpio/gpio$PIN_NO

if [ $? -ne 0 ]; then
        echo "Enabling pin $PIN_NO..." >&3
        echo $PIN_NO > /sys/class/gpio/export
        usleep 50000

        # Exit if gpio was not successfully enabled
        ls /sys/class/gpio/gpio$PIN_NO
        if [ $? -ne 0 ]; then
            exit 1
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

