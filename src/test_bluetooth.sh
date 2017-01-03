#!/bin/sh
#
# Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies
# and/or licensors
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to
#    endorse or promote products derived from this software without specific prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
# WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This script will test bluetooth by
#scanning, pinging any bluetooth device, and allowing pairing to the DUT.

. /usr/lib/board_test_common.sh

TRIALS=50
PACKET_SIZE=44
PASS_PERCENTAGE_THRESHOLD=95
PING=0
SCAN=0
ENABLE_DUT=false

USAGE="
Usage: $0 options

Details:
This script allows to do following things:
1. Configure bluetooth
2. Scan and show any bluetooth device in the vicinity
3. Ping any blutooth device

OPTIONS:
-h         Show this message
-s         Scan devices
-p  <arg>  ping device e.g -p 00:22:61:90:87:CD
-c  <arg>  Number of times to ping, default 50, and pass -c 0 for continuous mode
-t  <arg>  Minimum ping success percentage required to pass the test, default 95
-v         Verbose
-V         Show package version
-d         Enable DUT mode
"

while getopts "p:c:dt:svVh" opt; do
	case $opt in
		s)
			SCAN=1
			;;
		p)
			PING=1
			BADDR=$OPTARG
			;;
		c)
			TRIALS=$OPTARG
			;;
		t)
			PASS_PERCENTAGE_THRESHOLD=$OPTARG
			;;
		v)
			LOG_LEVEL=$DEBUG
			;;
		V)
			echo "version = "$(cat $BOARD_TEST_PATH/version)
			exit $SUCCESS
			;;
		d)
			ENABLE_DUT=true
			;;
		h)
			echo "${USAGE}"
			exit $SUCCESS
			;;
		\?)
			echo "${USAGE}"
			exit $FAILURE
			;;
	esac
done

redirect_output_and_error $LOG_LEVEL


LOG_INFO "\n************************** Bluetooth test **************************\n"


if [ $SCAN -eq 1 ]; then
	LOG_INFO "Scanning bluetooth devices\n"
	RESULT=$(hcitool scan | awk '{ if (NR>1) { print $1,$2}  }')
	if [ $? -ne $SUCCESS ] || [ -z "$RESULT" ]; then
		LOG_ERROR "SCAN FAIL: No device found"
		exit $FAILURE
	else
		LOG_INFO "$RESULT"
		LOG_INFO "SCAN PASS\n"
	fi
fi

if [ $PING -eq 1 ]; then
	if [ $TRIALS -eq 0 ]; then
		LOG_INFO "Pinging bluetooth device with addr $BADDR continuously"

		continuous_ping bt "dummy" $BADDR $PACKET_SIZE 0
	else
		# bluetooth ping doesn't require interface so passing "dummy"
		LOG_INFO "Pinging bluetooth device with addr $BADDR\n"
		get_ping_percentage bt "dummy" $BADDR $PACKET_SIZE $TRIALS
		PASS_PERCENTAGE=$?
		if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
			LOG_INFO "PING PASS"
		else
			LOG_INFO "PING FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%"
			exit $FAILURE
		fi
	fi
fi


if [ $ENABLE_DUT = true ]; then
	LOG_INFO "Enabling DUT mode using HCI commands\n"
	sleep 1
	hcitool cmd 0x03 0x1a 0x03
	if [ $? -ne $SUCCESS ]; then
		LOG_ERROR "Failed to enable BT enquiry scan"
		exit $FAILURE
	else
		sleep 1
		hcitool cmd 0x03 0x05 0x02 0x00 0x03
		if [ $? -ne $SUCCESS ]; then
			LOG_ERROR "Failed to set event filter to allow all connections with role switch"
			exit $FAILURE
		else
			sleep 1
			hcitool cmd 0x06 0x0003
			if [ $? -ne $SUCCESS ]; then
				LOG_ERROR "Failed to enter BT test mode"
				exit $FAILURE
			fi
		fi
	fi
	LOG_INFO "DUT mode enabled"
fi
