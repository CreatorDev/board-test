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
# The test takes one argument specifying mikroBUS number (1 or 2).

LOG_LEVEL=1

source click_common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

get_mikrobus_number $1
MIKROBUS=$?

echo -e "\n**************************  CLICK MOTION test **************************\n" >&3

if [ $MIKROBUS -eq 1 ]; then
    GPIO_NUM=21
else
    GPIO_NUM=24
fi

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
