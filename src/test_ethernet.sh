# This script will test ethernet by pinging www.google.com else any url provided using -u option

LOG_LEVEL=1
HOST=www.google.com
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
-c	Number of times to ping e.g -c 50
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

echo -e "Pinging to $HOST $TRIALS number of times" >&3

get_ping_percentage ipv4 $INTERFACE $HOST $TRIALS
PASS_PERCENTAGE=$?
if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
    echo -e "PASS \n" >&3
    exit 0
else
    echo -e "FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%\n" >&3
    exit 1
fi
