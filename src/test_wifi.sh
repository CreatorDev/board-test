# This script will test wifi by pinging www.google.com
# Export WLAN_SSID and WLAN_PASSWORD to run this test

LOG_LEVEL=1
HOST=www.google.com
INTERFACE=wlan0
TRIALS=5

source common.sh
parse_command_line $@
redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* Wifi test *************************************\n" >&3

if [ -z ${WLAN_SSID} ];then
	echo "Please export WLAN_SSID to run this script" >&3
	exit 1
fi

if [ -z ${WLAN_PASSWORD} ];then
	echo "Please export WLAN_PASSWORD to run this script" >&3
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

if [ $? == 0 ];then
	ping $HOST -w $TRIALS -I $INTERFACE
	{
		[ $? == 0 ] && echo "PASS" || (echo "FAIL"; exit 1)
	} >&3
else
	echo "FAIL" >&3
	exit 1
fi
