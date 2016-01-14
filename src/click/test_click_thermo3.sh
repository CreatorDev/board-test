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
			if [[ $MIKROBUS -ne 1 && $MIKROBUS -ne 2 ]]; then
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

echo -e "\n**************************  CLICK THERMO3 test **************************\n" >&3

enable_i2c_driver

# Run the actual test
VAL=`./test_click_read_thermo3 -m $MIKROBUS`
echo "temperature: $VAL" >&3

# Convert float to integer and check if in expected range
TEMP=${VAL%.*}
if [ "$TEMP" -ge 5 -a "$TEMP" -le 50 ]
then
    echo "PASS" >&3
else
    echo "FAIL (value not in expected range)" >&3
fi
