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

# This script will test wifi by pinging any url/IP provided using -u option or default gateway
# if nothing is found out of these then it pings www.google.com
# Export WLAN_SSID and WLAN_PASSWORD to run this test for marduk, for beetle export WLAN_ENCRYPTION
# as well

LOG_LEVEL=1
INTERFACE=wlan0
TRIALS=20
BOARD=marduk
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
-a	which antenna(1,2) to use for wifi, only for beetle eg -a 1
-v	Verbose
-V	Show package version

EOF
}

while getopts "u:c:a:vVh" opt; do
	case $opt in
		u)
			HOST=$OPTARG;;
		c)
			TRIALS=$OPTARG;;
		a)
			ANTENNA=$OPTARG
			if [ $ANTENNA -ne 1 ] && [ $ANTENNA -ne 2 ]; then
				echo -e "invalid antenna number, antenna should be either 1 or 2"
				exit 1
			fi
			;;
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

echo -e "\n******************************* Wifi test *************************************\n" >&3

if [ -z ${WLAN_SSID} ];then
	echo "Please export WLAN_SSID to run this script e.g export WLAN_SSID=ABCD" >&3
	exit 1
fi

if [ -z ${WLAN_PASSWORD} ];then
	echo "Please export WLAN_PASSWORD to run this script e.g export WLAN_PASSWORD=xyz" >&3
	exit 1
fi

{
	uci
} >&4
if [ $? -eq 0 ]; then
	if [ -z ${WLAN_ENCRYPTION} ];then
		echo "Please export WLAN_ENCRYPTION to run this script e.g export WLAN_ENCRYPTION=psk" >&3
		exit 1
	fi
	# disable ethernet
	uci set network.eth.enabled=0
	# enable wifi
	uci set network.sta.enabled=1
	uci commit network

	if [ ! "$(uci get wireless.sta)" == "wifi-iface" ]; then
		uci set wireless.sta=wifi-iface
		uci set wireless.sta.device=radio0
		uci set wireless.sta.network=sta
		uci set wireless.sta.mode=sta
	fi
	uci set wireless.sta.ssid=$WLAN_SSID
	uci set wireless.sta.encryption=$WLAN_ENCRYPTION
	uci set wireless.sta.key=$WLAN_PASSWORD
	uci commit wireless
	if [ -n "$ANTENNA" ]; then
		echo -e "setting antenna $ANTENNA" >&3
		echo uccp_num_spatial_streams=1 > /proc/uccp420/params
		echo antenna_sel=$ANTENNA > /proc/uccp420/params
	fi
	/etc/init.d/S39netifd restart
	echo -e "configuring wifi..." >&3
	sleep 20
	WLAN_STATUS=0
	# Interface name is getting changed everytime we write in /proc/uccp420/params
	# So get the interface name before pinging
	INTERFACE=$(ifconfig | grep wlan | awk '{print $1}')
	if [ -n "$INTERFACE" ]; then
		# Check if wlan is assigned IP address or not
		/sbin/ifconfig $INTERFACE >&4 && WLAN_STATUS=`/sbin/ifconfig $INTERFACE | grep "inet addr:" -c`
	fi
	if [ $WLAN_STATUS -eq 0 ];then
		echo -e "Couldn't configure wifi" >&3
		exit 1
	fi
else
	# this is for marduk where uci is not applicable

	WLAN_STATUS=0
	# Check if wlan is assigned IP address or not
	/sbin/ifconfig $INTERFACE >&4 && WLAN_STATUS=`/sbin/ifconfig $INTERFACE | grep "inet addr:" -c`
	# Assign IP to wlan if not assigned
	if [ $WLAN_STATUS -eq 0 ];then
		wpa_passphrase $WLAN_SSID $WLAN_PASSWORD > wlan_supplicant.conf &&\
		ifconfig $INTERFACE up  &&\
		(wpa_supplicant -Dnl80211 -i$INTERFACE -c ./wlan_supplicant.conf -B) &&\
		sleep 2 &&\
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


if [ $? == 0 ];then
	if [ $TRIALS -eq 0 ];then
		echo "Pinging to $HOST continuously" >&3

		continuous_ping ipv4 $INTERFACE $HOST
	else
		echo "Pinging to $HOST $TRIALS number of times" >&3

		get_ping_percentage ipv4 $INTERFACE $HOST $TRIALS
		PASS_PERCENTAGE=$?
		if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
			echo -e "PASS \n" >&3
		else
			echo -e "FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%\n" >&3
			exit 1
		fi
	fi
else
	echo "FAIL" >&3
	exit 1
fi
