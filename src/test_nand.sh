# This script will check if nand device has been created or not

LOG_LEVEL=1

source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* Nand test *************************************\n" >&3

ls /dev/mtd1
{
	[ $? == 0 ] && echo "PASS" || (echo "FAIL (Nand device not found)"; exit 1)
} >&3
