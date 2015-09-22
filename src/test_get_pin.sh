# can be used for getting state of GPIO only if it can be exported from user space
# ensure that MFIO number is correct

LOG_LEVEL=1
source common.sh
redirect_output_and_error $LOG_LEVEL

Usage() {
	echo -e "Usage: Give argument as MFIO number e.g. ./test_get_pin.sh 76\n"  >&3
}

if [ "$#" -lt 1 ];then
	Usage
	exit 1
fi

MFIO=$1

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
	# set pin direction as input
	DIRECTION=`cat /sys/class/gpio/gpio$MFIO/direction`
	if [ "$DIRECTION" != "in" ]; then
		echo in > /sys/class/gpio/gpio$MFIO/direction
	fi

	#get value
	cat /sys/class/gpio/gpio$MFIO/value
}>&3

