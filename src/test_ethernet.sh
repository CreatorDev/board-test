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
