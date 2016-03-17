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

# This test tries to read one register from Infineon chip

LOG_LEVEL=1
MARDUK_TPM_RST_MFIO=42
source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-b	board type (beetle, marduk) e.g -b marduk
-v	Verbose
-V	Show package version

EOF
}

while getopts "b:vVh" opt; do
	case $opt in
		b)
			BOARD_NAME=$OPTARG
			if [ "marduk" = $BOARD_NAME ]; then
				# Set up TPM_RST MFIO
				sh test_set_pin.sh $MARDUK_TPM_RST_MFIO 1
				I2C_BUS=0
			elif [ "beetle" = $BOARD_NAME ]; then
				I2C_BUS=0
			else
				echo -e "Board name not valid\n"
				exit 1;
			fi
			;;
		i)
			I2C_BUS=$OPTARG;;
		v)
			LOG_LEVEL=2;;
		V)
			echo -n "version = "
			cat version
			exit 0;;
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
	VALUE=`i2cget -y -f $I2C_BUS 0x20 0x6 w`
}>&4
EXPECTED=0x15d1
if [ "$VALUE" = "$EXPECTED" ]; then
        echo -e "PASS: TPM chip found \n" >&3
else
        echo -e "FAIL: Read failed \n" >&3
		exit 1
fi
