# This script will test bluetooth by
#scanning, pinging any bluetooth device, and allowing pairing to the DUT.
LOG_LEVEL=1
BLUETOOTH_RESET_MFIO=43
TRIALS=50
PASS_PERCENTAGE_THRESHOLD=95
ALLOW_PAIRING=0
source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
	Usage: sh test_bluetooth.sh [options]
	Details:
	This script allows to do following things:
		1) Configure bluetooth
		2) Allow discovery and pairing of device.
		3) Scan and show any bluetooth device in the vicinity
		4) Ping any blutooth device

-s	Scan devices
-p	ping device e.g -p 00:22:61:90:87:CD
-u	enable device discovery and pairing
-c	Number of times to ping e.g -c 50
-v	Verbose

EOF
}

while getopts "p:c:svuh" opt; do
	case $opt in
		s)
			SCAN=1;;
		p)
			PING=1
			BADDR=$OPTARG;;
		c)
			TRIALS=$OPTARG;;
		u)
			ALLOW_PAIRING=1;;
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

echo -e "\n**************************  Bluetooth test**************************\n" >&3
HCI_PS_ID=$(ps aux | grep -v grep | grep hciattach | awk '{print $1}')

if [ -z $HCI_PS_ID ];then
	# Set up BT_RST_N MFIO
	sh test_set_pin.sh $BLUETOOTH_RESET_MFIO 1
	# Set up CSR PSKEYs
	PSKEYS=/tmp/concerto.psr
cat <<EOF > $PSKEYS
// PSKEY_ANA_FREQ
// 26MHz reference clock
&01fe = 6590
// PSKEY_HOST_INTERFACE
// BCSP host interface
&01f9 = 0001
// PSKEY_UART_CONFIG_BCSP
// &01bf = 080E
&01bf = 0806
// PSKEY_UART_BITRATE
// 115200 baud rate
&01ea = 0001 c200
// PSKEY_CLOCK_REQUEST_ENABLE
// Reset to 0x0000 for not using the PIO[2] and PIO[3] and disenabling TXCO
&0246 = 0000
//PSKEY_DEEP_SLEEP_STATE
&0229 = 0000
EOF

	# Bring up CSR
	DEVICE=/dev/ttyS0
	BAUD_RATE=115200
	BAUD_RATE_LATER=115200
	echo -e "Initializing device $DEVICE\n"
	bccmd -t bcsp -d $DEVICE -b $BAUD_RATE buildname &&\
	bccmd -t bcsp -d $DEVICE -b $BAUD_RATE psload -r $PSKEYS &&\
	(hciattach -s $BAUD_RATE_LATER $DEVICE bcsp $BAUD_RATE_LATER noflow)

	{
		if [ $? == 0 ]; then
			echo "Initialization Pass"
		else
			echo "Initialization Fail"
			exit 1
		fi
	} >&3
	sleep 5
fi
FAIL=0
echo -e "Configuring bluetooth device\n"
hciconfig hci0 reset &&\
hciconfig hcpi0 up &&\
hciconfig hci0 piscan &&\
hciconfig hci0 version &&\
hcitool dev || FAIL=1
if [ $FAIL -eq 1 ]; then
	echo -e "FAIL\n" >&3
	exit 1
fi

if [ $ALLOW_PAIRING -eq 1 ]; then
echo -e "Starting bluetooth daemon\n"
{
	BLUETOOTHD_PS_ID=$(ps aux | grep -v grep | grep bluetoothd | awk '{print $1}')
	if [ -z $BLUETOOTHD_PS_ID ]; then
		bluetoothd
		if [ $? -ne 0 ]; then
			echo -e "FAIL: Failed to start bluetooth daemon\n" >&3
			exit 1
		fi
		sleep 1
		export BTADAPTER=$(echo `dbus-send --system --dest=org.bluez --print-reply / org.bluez.Manager.DefaultAdapter | tail -1 | sed 's/^.*"\(.*\)".*$/\1/'`)
		{
			dbus-send --system --dest=org.bluez --print-reply $BTADAPTER org.bluez.Adapter.SetProperty string:Discoverable variant:boolean:true
			if [ $? -ne 0 ]; then
				echo -e "FAIL: dbus-send command failed\n" >&3
				exit 1
			fi
		} >&4

	fi
} >&3
fi

if [ $SCAN -eq 1 ]; then
echo -e "Scanning bluetooth devices\n"
{
	RESULT=$(hcitool scan | awk '{ if (NR>1) { print $1,$2}  }')
	if [ $? -ne 0 ] || [ -z $RESULT ]; then
		echo "SCAN FAIL: No device found"
		exit 1
	else
		echo -e "$RESULT"
		echo -e "\nSCAN PASS\n"
	fi
} >&3
fi

if [ $PING -eq 1 ]; then
	# bluetooth ping doesn't require interface so passing "dummy"
	echo -e "Pinging bluetooth device with addr $BADDR\n"
	get_ping_percentage bt "dummy" $BADDR $TRIALS
	PASS_PERCENTAGE=$?
	if [ $PASS_PERCENTAGE -gt $PASS_PERCENTAGE_THRESHOLD ]; then
	    echo -e "PING PASS" >&3
	else
	    echo -e "PING FAIL, pass percent not more than $PASS_PERCENTAGE_THRESHOLD%" >&3
	    exit 1
	fi
fi
