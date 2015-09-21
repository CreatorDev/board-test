# This script will try to run scripts which don't require manual intervention
# other tests have to be run manually

source common.sh
parse_command_line $@

./test_ethernet.sh $@
./test_nand.sh $@
./test_nor.sh $@
./test_sdcard.sh $@
./test_wifi.sh $@
./test_audio.sh -d hw:0,2 $@
./test_tpm.sh -i 0
./test_heartbeat_led.sh
./test_spi_uart.sh

echo ""
