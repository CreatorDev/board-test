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
