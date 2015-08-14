# This script will run ethernet, nand, nor, sdcard, wifi, audio test for ci40 board

source common.sh
parse_command_line $@

./test_ethernet.sh $@
./test_nand.sh $@
./test_nor.sh $@
./test_sdcard.sh $@
./test_wifi.sh $@
./test_audio.sh -d hw:0,2 $@

echo ""
