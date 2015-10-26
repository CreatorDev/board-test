#This script will read raw count from adc channels (0,1,2,3,6,7) and wait for the user input.
LOG_LEVEL=1
source common.sh
usage()
{
cat << EOF
Usage: sh test_adc_rawcount.sh
Details:
    Prints raw count for ADC channels (0,1,2,3,6,7)

OPTIONS:
-h	Show this message
-v	Verbose
-V	Show package version

EOF
}

while getopts "vVh" opt; do
	case $opt in
		v)
			LOG_LEVEL=2;;
		V)
			echo -n "version = " | cat - version
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

get_adc_channel_raw_count()
{
    CHANNEL=$1
    RAW_COUNT=`cat /sys/bus/iio/devices/iio\:device0/in_voltage"$CHANNEL"_raw`
    echo -e "channel $1 ADC value = $RAW_COUNT" >&3
}

while true
do
    echo -e "press \"enter/return\" key to read adc values and \"x\" key to exit" >&3
    read user_input
    if [ -z $user_input ]; then
        get_adc_channel_raw_count 0
        get_adc_channel_raw_count 1
        get_adc_channel_raw_count 2
        get_adc_channel_raw_count 3
        get_adc_channel_raw_count 6
        get_adc_channel_raw_count 7
    elif [[ $user_input = "x" ]]; then
        exit 0
    fi
done
