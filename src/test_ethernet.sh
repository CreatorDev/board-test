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

# This script will test ethernet by pinging any url/IP provided using -u option or default gateway
# if nothing is found out of these, then it pings www.google.com

. /usr/lib/board_test_common.sh

INTERFACE=eth0
TRIALS=20
PASS_PERCENTAGE_THRESHOLD=95

USAGE="
Usage: $0 options

OPTIONS:
-h         Show this message
-u  <arg>  Url/IP to ping e.g -u www.wikipedia.org or -u 192.18.95.80
-c  <arg>  Number of times to ping, default 20, and pass -c 0 for continuous mode
-v         Verbose
-V         Show package version
"

while getopts "u:c:vVh" opt; do
	case $opt in
		u)
			HOST=$OPTARG
			;;
		c)
			TRIALS=$OPTARG
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


LOG_INFO "\n******************************* Ethernet test *********************************\n"

CONFIG_CHANGED=false
# check if wifi is up
if [ $(ubus -t 1 call network.interface.sta status | grep "address" -c) -ne 0 ]; then
	# disable wifi
	LOG_DEBUG "disabling wifi"
	uci set network.sta.disabled=1
	CONFIG_CHANGED=true
fi

# check if ethernet is up
if [ $(ubus -t 1 call network.interface.wan status | grep "address" -c) -eq 0 ]; then
	# enable ethernet
	LOG_DEBUG "enabling ethernet"
	uci set network.wan.disabled=0
	CONFIG_CHANGED=true
fi

if [ $CONFIG_CHANGED = true ]; then
	uci commit network

	# S40network is present in buildroot while in OpenWRT,
	# network init script is used to configure network
	if [ -f /etc/init.d/S40network ]; then
		/etc/init.d/S40network restart
	else
		/etc/init.d/network reload
	fi

	TIMEOUT=0
	while [ $(ubus -t 1 call network.interface.wan status | grep "address" -c) -eq 0 ]
	do
		sleep 1
		TIMEOUT=$(($TIMEOUT + 1))
		if [ $TIMEOUT -eq 15 ]; then
			LOG_ERROR "Timed out. Exiting.\n"
			exit $FAILURE
		fi
	done
fi

# if host not provided by user, find the host from route
if [ -z $HOST ]; then
	HOST=$(/sbin/route -n | grep $INTERFACE | awk '{if (index($4,"G")) {print $2}}' | head -n 1)
	# if route fails for any reason use www.google.com
	if [ -z $HOST ]; then
		HOST=www.google.com
	fi
fi

if [ $TRIALS -eq 0 ]; then
	LOG_INFO "Pinging to $HOST continuously\n"

	continuous_ping ipv4 $INTERFACE $HOST
else
	LOG_INFO "Pinging to $HOST $TRIALS number of times\n"

	get_ping_percentage ipv4 $INTERFACE $HOST $TRIALS
	PASS_PERCENTAGE=$?
	if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
		LOG_INFO "PASS\n"
		exit $SUCCESS
	else
		LOG_ERROR "FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%\n"
		exit $FAILURE
	fi
fi
