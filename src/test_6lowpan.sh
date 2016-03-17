#!/bin/sh
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

# This test tries to initialize 6lowpan and then ping to the remote board
# When ran with -r option(remote board), then it only initializes 6lowpan(different IP addr)
# -c can be used for specifying ping count, -f is useful for changing 6lowpan channel


LOG_LEVEL=1
REMOTE_BOARD=false
CHANNEL=26
IP_ADDR="2001:db8:dead:beef::1"
REMOTE_IP_ADDR="2001:db8:dead:beef::5"
PAN_ID=0xbeef
WPAN_INTERFACE=wpan0
LOWPAN_INTERFACE=lowpan0
PHY=phy0
PING_COUNT=20
PASS_PERCENTAGE_THRESHOLD=90

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-r	if 6lowpan has to be configured on remote board
-c	number of times to ping, default 20, and pass -c 0 for continuous mode
-f	6lowpan channel to use [11 - 26] e.g -f 15
-d	only checks if interface exist
-v	Verbose
-V	Show package version

EOF
}

DETECT_INTERFACE=0

while getopts "c:f:drvVh" opt; do
	case $opt in
		r)
			REMOTE_BOARD=true;;
		c)
			PING_COUNT=$OPTARG;;
		f)
			CHANNEL=$OPTARG
			if [ $CHANNEL -lt 11 ] || [ $CHANNEL -gt 26 ];then
				echo -e "channel should be between 11 and 26, both inclusive\n"
				exit 1;
			fi
			;;
		d)
			DETECT_INTERFACE=1;;
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

redirect_output_and_error $LOG_LEVEL

echo -e "**************************  6lowpan test **************************\n" >&3

{
	/sbin/ifconfig $WPAN_INTERFACE
}>&4

if [ $? -ne 0 ];then
	echo -e "FAIL: $WPAN_INTERFACE interface doesn't exist\n" >&3
	exit 1
fi

# if interface exist means cc2520 has been detected, declare PASS
if [ $DETECT_INTERFACE -eq 1 ];then
	echo -e "PASS: interface exist\n" >&3
	exit 0
fi

# bring down the interface to configure channel and pan id
ifconfig $WPAN_INTERFACE down && sleep 1

if [ $? -ne 0 ];then
	echo -e "FAIL: can't bring down $WPAN_INTERFACE interface\n" >&3
	exit 1
fi

# based on whether it is test board or remote board decide the IP
if (( $REMOTE_BOARD )); then
	IP="$REMOTE_IP_ADDR/64"
else
	IP="$IP_ADDR/64"
fi

# configure channel and pan id
FAIL=0
echo -e "Configuring 6lowpan channel = $CHANNEL panid = $PAN_ID\n" >&3
iwpan phy $PHY set channel 0 $CHANNEL && \
sleep 1 && \
iwpan dev $WPAN_INTERFACE set pan_id $PAN_ID && \
sleep 1 || FAIL=1
if [ $FAIL -eq 1 ]; then
	echo -e "\nFAIL: Configuring channel and pan_id failed\n" >&3
	exit 1
fi


# configure lowpan0 interface if not done yet
{
	/sbin/ifconfig $LOWPAN_INTERFACE
}>&4

if [ $? -ne 0 ];then
	echo -e "Bringing up $LOWPAN_INTERFACE\n" >&3
	ip link add link $WPAN_INTERFACE name $LOWPAN_INTERFACE type lowpan && \
	sleep 1 || FAIL=1
	if [ $FAIL -eq 1 ]; then
		echo -e "\nFAIL: Adding $LOWPAN_INTERFACE failed\n" >&3
		exit 1
	fi
fi

# configure IP address if not done yet
{
	/sbin/ifconfig $LOWPAN_INTERFACE | grep "inet6 addr: $IP" -c && IP_ASSIGNED=true || IP_ASSIGNED=false
}>&4

if [[ "$IP_ASSIGNED" = "false" ]];then
	echo -e "Configuring IP = $IP\n" >&3
	ip addr add $IP dev $LOWPAN_INTERFACE &&\
	sleep 1 || FAIL=1
	if [ $FAIL -eq 1 ]; then
		echo -e "\nFAIL: Configuring IP failed\n" >&3
		exit 1
	fi
fi


# all done, bring up the interfaces
ifconfig $WPAN_INTERFACE up && \
sleep 1 && \
ifconfig $LOWPAN_INTERFACE up && \
sleep 1 || FAIL=1
if [ $FAIL -eq 1 ]; then
	echo -e "\nFAIL: Bringing up interface failed\n" >&3
	exit 1
fi

# ping to the remote board
if (( ! $REMOTE_BOARD )); then
	echo -e "Pinging to $REMOTE_IP_ADDR, please check if remote board is powered ON and configured\n" >&3

	if [ $PING_COUNT -eq 0 ]; then
		echo "Pinging to $REMOTE_IP_ADDR continuously" >&3

		continuous_ping ipv6 $LOWPAN_INTERFACE $REMOTE_IP_ADDR
	else
		echo "Pinging to $REMOTE_IP_ADDR $PING_COUNT number of times" >&3

		get_ping_percentage ipv6 $LOWPAN_INTERFACE $REMOTE_IP_ADDR $PING_COUNT
		PASS_PERCENTAGE=$?
		if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
		    echo -e "PASS\n" >&3
		else
		    echo -e "FAIL: pass percent is not greater than or equal to $PASS_PERCENTAGE_THRESHOLD%\n" >&3
		    exit 1
		fi
	fi
fi
