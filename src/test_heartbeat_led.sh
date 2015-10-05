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

# This test will blink the Heartbeat LED on the board

LOG_LEVEL=1
BLINK_DELAY_USEC=50000
BLINK_COUNT=10

source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

echo -e "\n**************************  HEARTBEAT LED test **************************\n" >&3

HEARBEAT_LED=76

for j in $(seq 1 $BLINK_COUNT)
do
        sh test_set_pin.sh $HEARBEAT_LED 0
        usleep $BLINK_DELAY_USEC
        sh test_set_pin.sh $HEARBEAT_LED 1
        usleep $BLINK_DELAY_USEC
done

echo -e "\nDid Heartbeat LED blink?\n" >&3
show_result_based_on_switch_pressed
