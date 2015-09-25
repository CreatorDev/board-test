# This test tries to initialize 6lowpan and then ping to the remote board
# When ran with -r option(remote board), then it only initializes 6lowpan(different IP addr)
# -c can be used for specifying ping count, -f is useful for changing 6lowpan channel


LOG_LEVEL=1
REMOTE_BOARD=0
CHANNEL=26
IP_ADDR="2001:db8:dead:beef::1"
REMOTE_IP_ADDR="2001:db8:dead:beef::5"
PAN_ID=0xbeef
WPAN_INTERFACE=wpan0
LOWPAN_INTERFACE=lowpan0
PHY=phy0
PING_COUNT=50
PASS_PERCENTAGE_THRESHOLD=90

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-r	if 6lowpan has to be configured on remote board
-c	number of times to ping e.g -c 50
-f	6lowpan channel to use [11 - 26] e.g -f 15
-v	Verbose

EOF
}

while getopts "c:f:rvh" opt; do
	case $opt in
		r)
			REMOTE_BOARD=1;;
		c)
			PING_COUNT=$OPTARG;;
		f)
			CHANNEL=$OPTARG
			if [ $CHANNEL -lt 11 ] || [ $CHANNEL -gt 26 ];then
				echo -e "channel should be between 11 and 26, both inclusive\n"
				exit 1;
			fi
			;;
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

redirect_output_and_error $LOG_LEVEL

echo -e "**************************  6lowpan test **************************\n" >&3

{
	/sbin/ifconfig $WPAN_INTERFACE
}>&4

if [ $? -ne 0 ];then
	echo -e "FAIL: $WPAN_INTERFACE interface doesn't exist\n" >&3
	exit 1
fi

# bring down the interface to configure channel and pan id
ifconfig $WPAN_INTERFACE down && sleep 1

if [ $? -ne 0 ];then
	echo -e "FAIL: can't bring down $WPAN_INTERFACE interface\n" >&3
	exit 1
fi

# based on whether it is test board or remote board decide the IP
if [ $REMOTE_BOARD -eq 1 ]; then
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
if [ $REMOTE_BOARD -eq 0 ]; then
	echo -e "Pinging to $REMOTE_IP_ADDR, please check if remote board is powered ON and configured\n" >&3

	get_ping_percentage ipv6 $LOWPAN_INTERFACE $REMOTE_IP_ADDR $PING_COUNT
	PASS_PERCENTAGE=$?
	if [ $PASS_PERCENTAGE -gt $PASS_PERCENTAGE_THRESHOLD ]; then
	    echo -e "PASS\n" >&3
	    exit 0
	else
	    echo -e "FAIL: pass percent not more than $PASS_PERCENTAGE_THRESHOLD%\n" >&3
	    exit 1
	fi
fi

