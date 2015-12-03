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

source click_common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

get_mikrobus_number $1
MIKROBUS=$?

echo -e "\n**************************  CLICK BARGARPH test **************************\n" >&3

enable_pwm $MIKROBUS

# Run the actual test
./test_click_write_bargraph -m $MIKROBUS -d

echo -e "\nDid BarGraph Display's segments light up?\n" >&3
show_result_based_on_switch_pressed
