usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-v	Verbose

EOF
}

parse_command_line()
{
	while getopts "vh" opt; do
		case $opt in
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
}

redirect_output_and_error()
{
	case $1 in
		1) exec 3>&1	4>/dev/null	1> /dev/null	2> /dev/null;;
		2) exec 3>&1	4>/dev/null;;
	esac
}

# pings specified number of times and returns the pass percentage
get_ping_percentage()
{
	PING_TYPE=$1
	INTERFACE=$2
	REMOTE_IP_ADDR=$3
	PING_COUNT=$4

	PASS_COUNT=0
	for i in $(seq 1 1 $PING_COUNT)
	do
		if [ $PING_TYPE = "ipv6" ]; then
			ping6 -I $INTERFACE $REMOTE_IP_ADDR -c 1
		else
			ping -I $INTERFACE $REMOTE_IP_ADDR -w 1
		fi
		ret=$?
		if [ $ret -eq "0" ]; then
			PASS_COUNT=$(($PASS_COUNT + 1))
		fi
		{
			printf "Progress %3d%%(%2d/%2d) Pass %3d%%(%2d/%2d)\r"\
				 $((i*100/PING_COUNT)) $i $PING_COUNT $((PASS_COUNT*100/i)) $PASS_COUNT $i
		}>&3
	done
	echo -e "\n" >&3

	percent=$((PASS_COUNT*100/PING_COUNT))
	return $percent
}
