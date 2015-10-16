# This tests currently enables click power and blinks the LED driven by the spi-uart chip

LOG_LEVEL=1
BLINK_DELAY_USEC=50000

source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

echo -e "\n**************************  SPI-UART chip test **************************\n" >&3

VALUE=`lsmod | grep sc16is7xx`
if [ -z "$VALUE" ]; then
	echo -e "Inserting sc16is7xx driver\n"
	modprobe sc16is7xx
fi

# sc16is7xx has 8 GPIO's, they get added from 504 to 511, 511 is connected to click power enable
# while others are connected to LED
echo -e "Enable Click Power \n"
CLICK_POWER_GPIO=511

sh test_set_pin.sh $CLICK_POWER_GPIO 1

echo -e "Blinking all Led's \n"

for i in 504 505 506 507 508 509 510
do
	sh test_set_pin.sh $i 1
	usleep $BLINK_DELAY_USEC
	sh test_set_pin.sh $i 0
	usleep $BLINK_DELAY_USEC
done

echo -e "\nDid all the LED's blink?\n" >&3
show_result_based_on_switch_pressed
