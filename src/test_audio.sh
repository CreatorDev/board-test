# This script will play sine wave on left and right channel for 4 loops

LOG_LEVEL=1
LOOPS=4

source common.sh

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-d	PCM device name e.g. -d hw:0,2
-v	Verbose

EOF
}

while getopts "d:vh" opt; do
	case $opt in
		d)
			PCM_DEVICE=$OPTARG;;
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

if [[ -z $PCM_DEVICE ]];then
	usage
	exit 1
fi

redirect_output_and_error $LOG_LEVEL

echo -e "\n******************************* Audio test ************************************\n" >&3

echo -e "Play audio for $LOOPS loops on $PCM_DEVICE\n" >&3

speaker-test -D $PCM_DEVICE -F S32_LE -c 2 -t sine -l $LOOPS

{
	[ $? == 0 ] && echo "PASS" || (echo "FAIL"; exit 1)
} >&3
