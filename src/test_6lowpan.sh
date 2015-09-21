# This test tries to initialize 6lowpan and then ping to the remote board
# When ran with -r option(remote board) then it only initializes 6lowpan


LOG_LEVEL=1
REMOTE_BOARD=0
DEFAULT_CHANNEL=26
IP_ADDR="2001:db8:dead:beef::1"
REMOTE_IP_ADDR="2001:db8:dead:beef::5"
PAN_ID=0xbeef
WPAN_INTERFACE=wpan0
LOWPAN_INTERFACE=lowpan0
PHY=phy0
#pings every 500 msec
PING_INTERVAL=0.5

source common.sh
redirect_output_and_error $LOG_LEVEL

Usage() {
	echo -e "\nUsage: Give optional -r if 6lowpan has to be configured on remote board\n" >&3
}

if [ "$#" -ge 1 ] && [ "$1" != "-r" ];then
	Usage
	exit 1
fi

if [ "$1" == "-r" ]; then
	REMOTE_BOARD=1
fi

echo -e "**************************  6lowpan test **************************\n" >&3

{
	/sbin/ifconfig $WPAN_INTERFACE
}>&4

if [ $? -ne 0 ];then
	echo -e "$WPAN_INTERFACE interface doesn't exist\n" >&3
	exit 1
fi

WPAN_STATUS=`cat /sys/class/net/$WPAN_INTERFACE/operstate`

if [ "$WPAN_STATUS" = "down" ];then

	# based on whether it is test board or remote board decide the IP
	if [ $REMOTE_BOARD -eq 1 ]; then
		IP="$REMOTE_IP_ADDR/64"
	else
		IP="$IP_ADDR/64"
	fi

	FAIL=0
	echo -e "Configuring 6lowpan channel = $DEFAULT_CHANNEL panid = $PAN_ID\n" >&3
	iwpan phy $PHY set channel 0 $DEFAULT_CHANNEL && \
	sleep 1 && \
	iwpan dev $WPAN_INTERFACE set pan_id $PAN_ID && \
	sleep 1 || FAIL=1
	if [ $FAIL -eq 1 ]; then
		echo -e "\nConfiguring channel and pan_id failed\n" >&3
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
			echo -e "\nAdding $LOWPAN_INTERFACE failed\n" >&3
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
			echo -e "\nConfiguring IP failed\n" >&3
			exit 1
		fi
	else
		echo -e "IP exist" >&3
	fi

	# all done, bring up the interfaces
	ifconfig $WPAN_INTERFACE up && \
	sleep 1 && \
	ifconfig $LOWPAN_INTERFACE up && \
	sleep 1 || FAIL=1
	if [ $FAIL -eq 1 ]; then
		echo -e "\nBringing up interface failed\n" >&3
		exit 1
	fi

else
	echo -e "Interface already configured\n" >&3
fi


if [ $REMOTE_BOARD -eq 0 ]; then
echo -e "Pinging to $REMOTE_IP_ADDR, please check if remote board is powered ON and configured\n" >&3
{
	ping6 -i $PING_INTERVAL -I $LOWPAN_INTERFACE $REMOTE_IP_ADDR
}>&3
fi

