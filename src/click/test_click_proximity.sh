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

LOG_LEVEL=1
COUNTER=1
MIKROBUS=1

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h     Show this message
-c     Number of times to run this test (0 means forever, default 1)
-m     mikroBUS number (1 or 2, default 1)
-v     Verbose
-V     Show package version

EOF
}

while getopts "c:m:vVh" opt; do
        case $opt in
               c)
                       COUNTER=$OPTARG;;
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

source click_common.sh
redirect_output_and_error $LOG_LEVEL

echo -e "\n**************************  CLICK PROXIMITY test **************************\n" >&3

# Offset (when distance is greater than around ~15 cm)
MIN_VALUE=2120

# Max value when literally touching the sensor
MAX_VALUE=52000

enable_i2c_driver

run_test()
{
        # Enable periodic measurements
        ./test_click_access_proximity -m $MIKROBUS -a e
        if [ $? -ne 0 ];then
            return 1
        fi

        # Make sure that a measurement has finished
        sleep 1

        # Read the value
        VAL=`./test_click_access_proximity -m $MIKROBUS -a p`
        if [ $? -ne 0 ];then
            return 1
        fi

        # Disable measurements
        ./test_click_access_proximity -m $MIKROBUS -a d
        if [ $? -ne 0 ];then
            return 1
        fi

        return 0
}

update_pass_fail_var()
{
        if [ $? -eq 0 -a $VAL -ge $MIN_VALUE -a $VAL -le $MAX_VALUE ]; then
                PASS=$((PASS + 1))
        else
                FAIL=$((FAIL + 1))
        fi
}

# Continuous test mode
if [ $COUNTER -eq 0 ]; then
        PASS=0
        FAIL=0
        echo -e "Testing click proximity sensor continuously\n" >&3
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

        echo "Proximity: $VAL" >&3
        if [ $PASS -ne 0 ]; then
                echo "PASS" >&3
        else
                echo "FAIL (value not in expected range)" >&3
        fi
        COUNTER=$((COUNTER - 1))
done

