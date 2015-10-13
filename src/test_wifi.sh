# This script will test wifi by pinging www.google.com else any url provided using -u option
# Export WLAN_SSID and WLAN_PASSWORD to run this test

LOG_LEVEL=1
HOST=www.google.com
INTERFACE=wlan0
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

EOF
}

while getopts "u:c:vh" opt; do
	case $opt in
		u)
			HOST=$OPTARG;;
		c)
			TRIALS=$OPTARG;;
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

echo -e "\n******************************* Wifi test *************************************\n" >&3

if [ -z ${WLAN_SSID} ];then
	echo "Please export WLAN_SSID to run this script e.g export WLAN_SSID=ABCD" >&3
	exit 1
fi

if [ -z ${WLAN_PASSWORD} ];then
	echo "Please export WLAN_PASSWORD to run this script e.g export WLAN_PASSWORD=xyz" >&3
	exit 1
fi

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

echo -e "Pinging to $HOST $TRIALS number of times" >&3

if [ $? == 0 ];then
	get_ping_percentage ipv4 $INTERFACE $HOST $TRIALS
	PASS_PERCENTAGE=$?
	if [ $PASS_PERCENTAGE -ge $PASS_PERCENTAGE_THRESHOLD ]; then
			echo -e "PASS \n" >&3
			exit 0
		else
			echo -e "FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%\n" >&3
			exit 1
	fi
else
	echo "FAIL" >&3
	exit 1
fi
