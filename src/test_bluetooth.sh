LOG_LEVEL=1
BLUETOOTH_RESET_MFIO=43
source common.sh
parse_command_line $@
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

	bccmd -t bcsp -d $DEVICE -b $BAUD_RATE buildname &&\
	bccmd -t bcsp -d $DEVICE -b $BAUD_RATE psload -r $PSKEYS &&\
	(hciattach -s $BAUD_RATE_LATER $DEVICE bcsp $BAUD_RATE_LATER noflow)

	{
		[ $? == 0 ] && echo "Initialization Pass" || (echo "Initialization Fail"; exit 1)

	} >&3
	sleep 5
fi
{
	hciconfig hci0 reset &&\
	hciconfig hci0 up &&\
	hciconfig hci0 piscan &&\
	hciconfig hci0 version &&\
	hcitool dev
	{
		hcitool scan
	} >&3
}

{
	[ $? == 0 ] && echo "PASS" || (echo "FAIL"; exit 1)
} >&3
