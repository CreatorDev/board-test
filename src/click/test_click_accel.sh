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

# This test reads accel and checks if the device ID is correct.
# The test takes one argument specifying mikroBUS number (1 or 2).

LOG_LEVEL=1
MIKROBUS=1
COUNTER=1

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

echo -e "\n**************************  CLICK ACCEL test **************************\n" >&3

update_pass_fail_var()
{
        if [ $? -eq 0 ]; then
                PASS=$((PASS + 1))
        else
                FAIL=$((FAIL + 1))
        fi
}

# Continuous test mode
if [ $COUNTER -eq 0 ]; then
        PASS=0
        FAIL=0
        echo -e "Testing accel click continuously\n" >&3
        while true; do
                ./test_click_read_accel -m $MIKROBUS
                update_pass_fail_var
                update_test_status "accel" 2 $PASS $FAIL
                sleep 1
        done
else
	echo -e "Running test for $COUNTER trials\n" >&3
	for j in $(seq 1 $COUNTER)
	do
        ./test_click_read_accel -m $MIKROBUS
        if [ $? -eq 0 ]; then
            echo "PASS" >&3
        else
            echo "FAIL" >&3
        fi
        sleep 1
	done
fi

