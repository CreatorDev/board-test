# This test tries to read one register from Infineon chip

LOG_LEVEL=1
source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-i	I2C bus number, for e.g. 'sh test_tpm.sh -i 0' for marduk
-v	Verbose

EOF
}

while getopts "i:vh" opt; do
	case $opt in
		i)
			I2C_BUS=$OPTARG;;
		v)
			LOG_LEVEL=2;;
		h)
			usage
			exit 0;;
		\?)
			usage
			exit 1;;
	esac
done

if [[ -z $I2C_BUS ]]; then
	usage
	exit 1
fi

redirect_output_and_error $LOG_LEVEL

echo -e "\n**************************  TPM test **************************\n" >&3

# Insert i2c_dev driver if not already inserted
VALUE=`lsmod | grep i2c_dev`
if [ -z "$VALUE" ]; then
	echo -e "Inserting i2c_dev driver\n"
	modprobe i2c_dev
fi

# DIDVID register address is 0x6 and should read 0x15d1 for SLB9645VQ1.2 chip
{
	VALUE=`i2cget -y $I2C_BUS 0x20 0x6 w`
}>&4
EXPECTED=0x15d1
if [ "$VALUE" = "$EXPECTED" ]; then
        echo -e "PASS: TPM chip found \n" >&3
else
        echo -e "FAIL: Read failed \n" >&3
		exit 1
fi
