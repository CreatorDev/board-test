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
# The test takes one argument specifying mikroBUS number (1 or 2).

LOG_LEVEL=1

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h     Show this message
-m     mikroBUS number (1 or 2)
-v     Verbose
-V     Show package version

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

echo -e "\n**************************  CLICK PROXIMITY test **************************\n" >&3

# Offset (when distance is greater than around ~15 cm)
MIN_VALUE=2120

# Max value when literally touching the sensor
MAX_VALUE=52000

enable_i2c_driver

# Enable periodic measurements
./test_click_access_proximity -m $MIKROBUS -a e

# Make sure that a measurement has finished
sleep 1

# Read the value
VAL=`./test_click_access_proximity -m $MIKROBUS -a p`

# Disable measurements
./test_click_access_proximity -m $MIKROBUS -a d

echo "Proximity: $VAL" >&3

if [ $VAL -ge $MIN_VALUE -a $VAL -le $MAX_VALUE ]
then
    echo "PASS" >&3
else
    echo "FAIL (value not in expected range)" >&3
    exit 1
fi
