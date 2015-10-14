# This script will try to run scripts which don't require manual intervention
# other tests have to be run manually

# source any environment variables if set by tester
ls ./env.sh &> /dev/null
if [ $? -eq 0 ];then
	source ./env.sh
fi
source common.sh
parse_command_line $@

print_result()
{
	TEST_NAME=$1
	TEST_STATUS=$2

	RED='\033[0;31m'
	NC='\033[0m' # No Color

	if [ $TEST_STATUS -eq 0 ];then
		echo -e "$TEST_NAME: PASS\n"
	else
		echo -e "$TEST_NAME: ${RED}FAIL${NC}\n"
	fi
}

./test_audio.sh -d hw:0,2 $@
AUDIO_TEST=$?
./test_nor.sh $@
NOR_TEST=$?
./test_nand.sh $@
NAND_TEST=$?
./test_sdcard.sh $@
SDCARD_TEST=$?
./test_tpm.sh -b marduk $@
TPM_TEST=$?
./test_heartbeat_led.sh $@
HEARTBEAT_LED_TEST=$?
./test_spi_uart.sh $@
SPI_UART_TEST=$?
if [ -z ${ETHERNET_PING_HOST} ];then
	./test_ethernet.sh $@
else
	./test_ethernet.sh -u $ETHERNET_PING_HOST $@
fi
ETHERNET_TEST=$?
./test_bluetooth.sh -s $@
BLUETOOTH_TEST=$?
./test_6lowpan.sh -d $@
LOWPAN_TEST=$?
if [ -z ${WIFI_PING_HOST} ];then
	./test_wifi.sh $@
else
	./test_wifi.sh -u $WIFI_PING_HOST $@
fi
WIFI_TEST=$?

echo -e "\n******************************* RESULTS ************************************\n"
print_result "AUDIO" $AUDIO_TEST
print_result "NOR" $NOR_TEST
print_result "NAND" $NAND_TEST
print_result "SDCARD" $SDCARD_TEST
print_result "TPM" $TPM_TEST
print_result "SPI_UART" $SPI_UART_TEST
print_result "ETHERNET" $ETHERNET_TEST
print_result "BLUETOOTH" $BLUETOOTH_TEST
print_result "6LOWPAN" $LOWPAN_TEST
print_result "WIFI" $WIFI_TEST
