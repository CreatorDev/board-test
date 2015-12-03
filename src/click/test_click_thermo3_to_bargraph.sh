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
# lights up an amount of segments on BarGraph's Display depending on
# the value.
# Assumed setup:
# BarGraph Click sitting in mikroBUS 1
# Thermo3 Click sitting in mikroBUS 2
#
# Input argument specifies base temperature. For example if actual temperature
# is 26 and specified base is 20, then 6 display segments will be lit up.

LOG_LEVEL=1

source click_common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

MARGIN_BOT=$1
SEGMENTS=10

echo -e "\n**************************  CLICK THERMO3 + BARGRAPH combined test **************************\n" >&3

if [ -z "$MARGIN_BOT" ]
then
    echo -e "Please provide base temperature in celsius, for example 20" >&3
    exit 1
fi

echo -e "base temperature: $MARGIN_BOT\n"

enable_i2c_driver

VAL=`./test_click_read_thermo3 -m 2`
echo -e "measured temperature: $VAL\n"
# drop fraction
VAL=${VAL%.*}

MARGIN_TOP=$((MARGIN_BOT+SEGMENTS))
if [ "$VAL" -ge "$MARGIN_TOP" ]; then ACTIVE=10
elif [ "$VAL" -le "$MARGIN_BOT" ]; then ACTIVE=0
else ACTIVE=$((VAL - MARGIN_BOT))
fi

enable_pwm 1

./test_click_write_bargraph -m 1 -s "$(( (1<<ACTIVE) - 1 ))"

echo -e "Are there $ACTIVE active segments?\n" >&3
show_result_based_on_switch_pressed
