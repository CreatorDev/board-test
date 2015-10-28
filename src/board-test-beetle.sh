# This script will run all the test scripts for beetle board

# source any environment variables if set by tester
ls ./env.sh &> /dev/null
if [ $? -eq 0 ];then
	source ./env.sh
fi
source common.sh
parse_command_line $@

./test_audio.sh -d hw:0,0 $@
AUDIO_TEST=$?
./test_nor.sh $@
NOR_TEST=$?
./test_nand.sh $@
NAND_TEST=$?
./test_sdcard.sh $@
SDCARD_TEST=$?
./test_tpm.sh -b beetle $@
TPM_TEST=$?
if [ -z ${ETHERNET_PING_HOST} ];then
	./test_ethernet.sh $@
else
	./test_ethernet.sh -u $ETHERNET_PING_HOST $@
fi
ETHERNET_TEST=$?
if [ -z ${WIFI_PING_HOST} ];then
        ./test_wifi.sh -b beetle $@
else
        ./test_wifi.sh -u $WIFI_PING_HOST -b beetle $@
fi
WIFI_TEST=$?
./test_bluetooth.sh -s -b beetle $@
BLUETOOTH_TEST=$?
./test_adc_rawcount.sh $@
ADC_TEST=$?
./test_gpio_beetle.sh $@
GPIO_TEST=$?

echo -e "\n******************************* RESULTS ************************************\n"
print_result "AUDIO" $AUDIO_TEST
print_result "NOR" $NOR_TEST
print_result "NAND" $NAND_TEST
print_result "SDCARD" $SDCARD_TEST
print_result "TPM" $TPM_TEST
print_result "ETHERNET" $ETHERNET_TEST
print_result "WIFI" $WIFI_TEST
print_result "BLUETOOTH" $BLUETOOTH_TEST
print_result "ADC" $ADC_TEST
print_result "GPIO" $GPIO_TEST