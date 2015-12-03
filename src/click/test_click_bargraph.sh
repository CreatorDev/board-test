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

# This test sets bargraph click display's segments.
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

PWM_NUM=$(( MIKROBUS - 1 ))
PWM_DIR="/sys/class/pwm/pwmchip0/pwm${PWM_NUM}/"

echo -e "\n**************************  CLICK BARGARPH test **************************\n" >&3

# Enable PWM
if [ ! -d "$PWM_DIR" ]; then
    echo -e "Exporting and enabling pwm on mikroBUS ${MIKROBUS}\n"
    echo $PWM_NUM > /sys/class/pwm/pwmchip0/export
    echo 100000 > "$PWM_DIR/period"
    echo 50000 > "$PWM_DIR/duty_cycle"
    echo 1 > "$PWM_DIR/enable"
fi

# Run the actual test
./test_click_write_bargraph -m $MIKROBUS -d

echo -e "\nDid BarGraph Display's segments light up?\n" >&3
show_result_based_on_switch_pressed
