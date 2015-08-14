# This script will check if nor device has been created or not

LOG_LEVEL=1

source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* Nor test **************************************\n" >&3

ls /dev/mtd0
{
	[ $? == 0 ] && echo "PASS" || (echo "FAIL (Nor device not found)"; exit 1)
} >&3
