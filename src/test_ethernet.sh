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

# This script will test ethernet by pinging any url/IP provided using -u option or default gateway
# if nothing is found out of these, then it pings www.google.com

LOG_LEVEL=1
INTERFACE=eth0
TRIALS=20
PASS_PERCENTAGE_THRESHOLD=95

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-u	Url/IP to ping e.g -u www.wikipedia.org or -u 192.18.95.80
-c	Number of times to ping, default 20, and pass -c 0 for continuous mode
-v	Verbose
-V	Show package version

EOF
}

while getopts "u:c:vVh" opt; do
	case $opt in
		u)
			HOST=$OPTARG;;
		c)
			TRIALS=$OPTARG;;
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
echo -e "\n******************************* Ethernet test *********************************\n" >&3

# check if uci exist
{
	uci
} >/dev/null 2>&1
if [ $? -eq 0 ]; then
	CONFIG_CHANGED=false
	# check if wifi is up
	ifconfig | grep wlan >&4
	if [ $? -eq 0 ]; then
		# disable wifi
		uci set network.sta.enabled=0
		CONFIG_CHANGED=true
	fi

	# check if ethernet is up
	ifconfig | grep eth >&4
	if [ $? -ne 0 ]; then
		# enable ethernet
		uci set network.eth.enabled=1
		CONFIG_CHANGED=true
	fi

	if (( $CONFIG_CHANGED )); then
		uci commit network

		# S39netifd is present in buildroot while in OpenWRT,
		# network init script is used to configure network
		if [ -f /etc/init.d/S39netifd ]; then
			/etc/init.d/S39netifd restart
		else
			/etc/init.d/network reload
		fi
		echo "configuring eth..." >&3
		sleep 15
	fi
else
	# this is for marduk where uci is not applicable

	ifconfig $INTERFACE up
	sleep 4
	ETH_STATUS=`cat /sys/class/net/$INTERFACE/operstate`

	if [ "$ETH_STATUS" = "down" ];then
		echo "FAIL (Not able to bring the interface up)" >&3
		exit 1
	fi

	{
		/sbin/ifconfig $INTERFACE | grep "inet addr:" -c && IP_ASSIGNED=true || IP_ASSIGNED=false
	} >&4

	if [[ "$IP_ASSIGNED" = "false" ]];then
		udhcpc -i $INTERFACE
	fi
fi

# if host not provided by user, find the host from route
if [ -z $HOST ];then
	HOST=$(/sbin/route -n | grep $INTERFACE | awk '{if (index($4,"G")) {print $2}}' | head -n 1)
	# if route fails for any reason use www.google.com
	if [ -z $HOST ];then
		HOST=www.google.com
	fi
fi

if [ $TRIALS -eq 0 ]; then
	echo "Pinging to $HOST continuously" >&3

	continuous_ping ipv4 $INTERFACE $HOST
else
	echo "Pinging to $HOST $TRIALS number of times" >&3

	get_ping_percentage ipv4 $INTERFACE $HOST $TRIALS
	PASS_PERCENTAGE=$?
	if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
	    echo -e "PASS \n" >&3
	    exit 0
	else
	    echo -e "FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%\n" >&3
	    exit 1
	fi
fi
