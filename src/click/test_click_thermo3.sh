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
# The test takes one argument specifying mikroBUS number (1 or 2).

LOG_LEVEL=1

source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

MIKROBUS=$1

if [ -z "$MIKROBUS" ]; then
    echo -e "Please provide mikroBUS number (1 or 2) as an argument\n" >&3
    exit 1
fi

if [ $MIKROBUS -ne 1 -a $MIKROBUS -ne 2 ]; then
    echo -e "Error: correct mikroBUS values are 1 or 2\n" >&3
    exit 1
fi

echo -e "\n**************************  CLICK THERMO3 test **************************\n" >&3

# Insert i2c_dev driver if not already inserted
VALUE=`lsmod | grep i2c_dev`
if [ -z "$VALUE" ]; then
    echo -e "Inserting i2c_dev driver\n"
    modprobe i2c_dev
fi

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