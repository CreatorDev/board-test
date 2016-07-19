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


# This test tries to initialize 6lowpan and then ping remote board (if -r option is passed)
# -c can be used for specifying ping count, and -f and -p can be used for changing 6lowpan channel and panid

. /usr/lib/board_test_common.sh

WPAN_INTERFACE=wpan0
LOWPAN_INTERFACE=lowpan0
PHY=phy0
PING_COUNT=20
PASS_PERCENTAGE_THRESHOLD=90
FAIL=0
PREFIX_LENGTH=48
TIME_INTERVAL=1000000
DETECT_INTERFACE=false
PACKET_SIZE=56

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-c  <arg>  Number of times to ping, default 20, and pass -c 0 for continuous mode
-f  <arg>  6lowpan channel to use [11 - 26] e.g -f 15
-i  <arg>  Set global IP
-r  <arg>  Ping IP
-p  <arg>  pan_id for 6lowpan e.g. -p 0xbeef
-t  <arg>  Time interval in microseconds between each ping, default 1 second, only used in continous mode
-s  <arg>  Pass percentage threshold, default ${PASS_PERCENTAGE_THRESHOLD}
-d         Only checks if interface exist
-l  <arg>  SIZE data bytes in packets (default:56)
-v         Verbose
-V         Show package version

Examples:

Set global ip on board
$0 -i 2001:db8:dead:beef::2

Ping remote board
$0 -r fe80::e057:73ff:fe1e:3dbb

Set channel and pan id
$0 -f 26 -p 0xbeef

Check lowpan interface existence
$0 -d
"

while getopts "c:f:i:r:p:t:s:dl:vVh" opt; do
	case $opt in
		c)
			PING_COUNT=$OPTARG
			;;
		f)
			CHANNEL=$OPTARG
			if [ $CHANNEL -lt 11 ] || [ $CHANNEL -gt 26 ]; then
				echo -e "Channel should be between 11 and 26, both inclusive\n"
				exit $FAILURE
			fi
			;;
		i)
			IP_ADDR=$OPTARG
			;;
		r)
			REMOTE_IP_ADDR=$OPTARG
			;;
		p)
			PAN_ID=$OPTARG
			;;
		t)
			TIME_INTERVAL=$OPTARG
			;;
		s)
			PASS_PERCENTAGE_THRESHOLD=$OPTARG
			if [ $PASS_PERCENTAGE_THRESHOLD -lt 0 ] || [ $PASS_PERCENTAGE_THRESHOLD -gt 100 ]; then
				echo -e "Pass percentage threshold must be in range 0..100\n"
				exit $FAILURE
			fi
			;;
		d)
			DETECT_INTERFACE=true
			;;
		l)
			PACKET_SIZE=$OPTARG
			if [ -z $REMOTE_IP_ADDR ]; then
				echo "Need remote IP option for packet size option"
				exit $FAILURE
			fi
			;;
		v)
			LOG_LEVEL=$DEBUG
			;;
		V)
			echo "version = "$(cat $BOARD_TEST_PATH/version)
			exit $SUCCESS
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

# Check whether packet size is a number
if ! [ "$PACKET_SIZE" -eq "$PACKET_SIZE" ] 2>/dev/null; then
	LOG_ERROR "Invalid packet size"
	exit $FAILURE
fi

if [ $# -lt 1 ]; then
	LOG_ERROR "Atleast one option is required to run the script\n"
	exit $FAILURE
fi


LOG_INFO "\n**************************  6lowpan test **************************\n"

/sbin/ifconfig $WPAN_INTERFACE >/dev/null

if [ $? -ne $SUCCESS ]; then
	LOG_ERROR "FAIL: $WPAN_INTERFACE interface doesn't exist\n"
	exit $FAILURE
else
	# if interface exist means 6lowpan chip has been detected, declare PASS
	if $DETECT_INTERFACE; then
		LOG_INFO "PASS: interface exist\n"
		exit $SUCCESS
	fi
fi

# Check whether remote board ip (to ping) is not set on this board
if ! [ -z $REMOTE_IP_ADDR ]; then
	/sbin/ifconfig $LOWPAN_INTERFACE | grep "inet6 addr: $REMOTE_IP_ADDR" >/dev/null
	if [ $? -eq $SUCCESS ]; then
		LOG_ERROR "Given remote board ip is already set to this board, try again with different" \
			"remote ip suffix\n"
		exit $FAILURE
	fi
fi

if ! [ -z $CHANNEL ] || ! [ -z $PAN_ID ]; then
	# bring down the interface before configuring channel and pan id
	ifconfig $WPAN_INTERFACE down && sleep 1
	if [ $? -ne $SUCCESS ];then
		LOG_ERROR "FAIL: can't bring down $WPAN_INTERFACE interface\n"
		exit $FAILURE
	fi
fi

if ! [ -z $CHANNEL ]; then
	# Configure channel if not already set
	LOG_INFO "Configure channel $CHANNEL\n"
	ALREADY_SET_CHANNEL=$(iwpan phy | grep current_channel | cut -d: -f2 | cut -d, -f1 | xargs)
	if [ $ALREADY_SET_CHANNEL != $CHANNEL ]; then
		iwpan phy $PHY set channel 0 $CHANNEL
		if [ $? -ne $SUCCESS ]; then
			LOG_ERROR "FAIL: couldn't set channel\n"
			exit $FAILURE
		fi
		sleep 1
	else
		LOG_INFO "Already set\n"
	fi
fi

if ! [ -z $PAN_ID ]; then
	# Configure pan id if not already set
	LOG_INFO "Configure pan id $PAN_ID\n"
	ALREADY_SET_PAN_ID=$(iwpan dev | grep pan_id | cut -d' ' -f2)
	if [ $ALREADY_SET_PAN_ID != $PAN_ID ]; then
		iwpan dev $WPAN_INTERFACE set pan_id $PAN_ID
		if [ $? -ne $SUCCESS ]; then
			LOG_ERROR "FAIL: couldn't set pan id\n"
			exit $FAILURE
		fi
		sleep 1
	else
		LOG_INFO "Already set\n"
	fi
fi

# configure lowpan0 interface if not done yet
/sbin/ifconfig $LOWPAN_INTERFACE >/dev/null
if [ $? -ne $SUCCESS ];then
	LOG_INFO "Bringing up $LOWPAN_INTERFACE\n"
	ip link add link $WPAN_INTERFACE name $LOWPAN_INTERFACE type lowpan && \
	sleep 1 || FAIL=1
	if [ $FAIL -eq 1 ]; then
		LOG_ERROR "FAIL: Adding $LOWPAN_INTERFACE failed\n"
		exit $FAILURE
	fi
fi

if ! [ -z $IP_ADDR ]; then
	# configure IP address
	{
		/sbin/ifconfig $LOWPAN_INTERFACE | grep "inet6 addr: $IP_ADDR" -c && IP_ASSIGNED=true || \
			IP_ASSIGNED=false
	}>/dev/null
	IP="$IP_ADDR/$PREFIX_LENGTH"
	if [ $IP_ASSIGNED = false ]; then
		LOG_INFO "Configuring IP $IP\n"
		ip addr add $IP dev $LOWPAN_INTERFACE &&\
		sleep 1 || FAIL=1
		if [ $FAIL -eq 1 ]; then
			LOG_ERROR "FAIL: couldn't set IP\n"
			exit $FAILURE
		fi
	else
		LOG_INFO "IP already set on this board\n"
	fi
fi

# all done, bring up the interfaces
ifconfig $WPAN_INTERFACE up && \
sleep 1 && \
ifconfig $LOWPAN_INTERFACE up && \
sleep 1 || FAIL=1
if [ $FAIL -eq 1 ]; then
	LOG_ERROR "FAIL: Bringing up interface failed\n"
	exit $FAILURE
fi


if ! [ -z $REMOTE_IP_ADDR ]; then
	# ping remote board
	if [ $PING_COUNT -eq 0 ]; then
		LOG_INFO "Pinging to $REMOTE_IP_ADDR continuously\n"
		continuous_ping ipv6 $LOWPAN_INTERFACE $REMOTE_IP_ADDR $PACKET_SIZE $TIME_INTERVAL

	else
		LOG_INFO "Pinging to $REMOTE_IP_ADDR $PING_COUNT number of times\n"
		get_ping_percentage ipv6 $LOWPAN_INTERFACE $REMOTE_IP_ADDR $PACKET_SIZE $PING_COUNT

		PASS_PERCENTAGE=$?
		if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
			LOG_INFO "PASS\n"
		else
			LOG_ERROR "FAIL: pass percent is not greater than or equal to $PASS_PERCENTAGE_THRESHOLD%\n"
			exit $FAILURE
		fi
	fi
fi
