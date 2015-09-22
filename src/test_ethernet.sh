# This script will test ethernet by pinging to www.google.com

LOG_LEVEL=1
HOST=www.google.com
INTERFACE=eth0
TRIALS=50
PASS_PERCENTAGE_THRESHOLD=95

source common.sh
parse_command_line $@
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

get_ping_percentage ipv4 $INTERFACE $HOST $TRIALS
PASS_PERCENTAGE=$?
if [ $PASS_PERCENTAGE -gt $PASS_PERCENTAGE_THRESHOLD ]; then
    echo -e "PASS \n" >&3
    exit 0
else
    echo -e "FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%\n" >&3
    exit 1
fi

