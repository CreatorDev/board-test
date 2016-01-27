#
# Copyright 2016 by Imagination Technologies Limited and/or its affiliated group companies.
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

# This test reads and writes to USB-UART click via UART interface.
# The click board must be connected to a desktop via USB. The board will
# act as a USB-UART bridge. The baudrate is set at 9600.
#
# Before running this test, a terminal must be opened and connected to the
# click board. The test will first send a string to the desktop. Then, in
# the terminal, you need to type characters until the Ci-40 asks for
# confirmation.


UART_FILE="/dev/ttySC0"
TEXT_OUT="Hello World from Ci40"
NB_CHAR=${#TEXT_OUT}
LOG_LEVEL=1
COUNTER=1

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-c	Number of trials, default 1
-f	UART file output, default /dev/ttySC0
-v	Verbose
-V	Show package version

EOF
}

while getopts "c:f:vVh" opt; do
	case $opt in
		c)
			COUNTER=$OPTARG;;
		f)
			UART_FILE=$OPTARG;;
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

source click_common.sh
redirect_output_and_error $LOG_LEVEL


echo -e "\n**************************  CLICK USB-UART test **************************\n" >&3

for j in $(seq 1 $COUNTER)
do
    echo -e "Writing to UART...\n" >&3
    echo ${TEXT_OUT} > ${UART_FILE}

    echo -e "Could you read \"${TEXT_OUT}\" from your terminal ?\n" >&3
    show_result_based_on_switch_pressed

    echo -e "Reading ${NB_CHAR} characters from UART\n" >&3
    read -n $NB_CHAR TMP < ${UART_FILE}; echo ${TMP} >&3

    echo -e "Is this what you wrote from your terminal ?\n" >&3
    show_result_based_on_switch_pressed
done

