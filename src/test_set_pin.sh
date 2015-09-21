# can be used for setting state of GPIO only if it can be exported from user space
# ensure that MFIO number is correct

LOG_LEVEL=1
source common.sh
redirect_output_and_error $LOG_LEVEL

Usage() {
	echo -e "Usage: Give argument as MFIO number and its value (1 or 0)  e.g. ./set_pin.sh 76 1\n"  >&3
}

if [ "$#" -lt 2 ];then
	Usage
	exit 1
fi

MFIO=$1
VALUE=$2

# check if value is either 1 or 0
if [ $VALUE -ne 1 ] && [ $VALUE -ne 0 ];then
	Usage
	exit 1
fi

# check if the gpio has already been exported
{
	ls /sys/class/gpio/gpio$MFIO
}>&4

if [ $? -ne 0 ];then
	{
		echo $MFIO > /sys/class/gpio/export
	}>&3
	# check for any error, some gpio cannot be exported
	if [ $? -ne 0 ];then
		exit 1
	fi
fi
{
	# set pin direction as output
	DIRECTION=`cat /sys/class/gpio/gpio$MFIO/direction`
	if [ "$DIRECTION" != "out" ]; then
		echo out > /sys/class/gpio/gpio$MFIO/direction
	fi

	#set value
	echo $VALUE > /sys/class/gpio/gpio$MFIO/value
}>&3

