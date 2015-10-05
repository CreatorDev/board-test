#
# Copyright 2015 by Imagination Technologies Limited and/or its affiliated group companies.
#
# All rights reserved.  No part of this software, either
# material or conceptual may be copied or distributed,
# transmitted, transcribed, stored in a retrieval system
# or translated into any human or computer language in any
# form by any means, electronic, mechanical, manual or
# other-wise, or disclosed to the third parties without the
# express written permission of Imagination Technologies
# Limited, Home Park Estate, Kings Langley, Hertfordshire,
# WD4 8LZ, U.K.

usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-v	Verbose
-V	Show package version

EOF
}

parse_command_line()
{
	while getopts "vVh" opt; do
		case $opt in
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
		elif [ $PING_TYPE = "bt" ];then
			l2ping $REMOTE_IP_ADDR -c 1
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

show_result_based_on_switch_pressed()
{
	{
		echo -e "Press switch 1 for pass or switch 2 for fail \n"
		./test_switch -w -t 10
		case $? in
			1)
				echo "PASS";;
			2)
				echo "FAIL"
				exit 1;;
			254)
				echo "FAIL (no key pressed within timeout)"
				exit 254;;
			255)
				echo "FAIL (some error in reading switches)"
				exit 255;;
		esac
	} >&3
}

print_result()
{
	TEST_NAME=$1
	TEST_STATUS=$2

	RED='\033[0;31m'
	NC='\033[0m' # No Color

	if [ $TEST_STATUS -eq 0 ];then
		echo -e "$TEST_NAME: PASS\n"
	else
		echo -e "$TEST_NAME: ${RED}FAIL${NC}\n"
	fi
}
