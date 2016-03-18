# Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies
# and/or licensors
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used to
#    endorse or promote products derived from this software without specific prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
# WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

single_ping()
{
	PING_TYPE=$1
	INTERFACE=$2
	REMOTE_IP_ADDR=$3

	if [ $PING_TYPE = "ipv6" ]; then
		ping6 -I $INTERFACE $REMOTE_IP_ADDR -c 1
	elif [ $PING_TYPE = "bt" ];then
		l2ping $REMOTE_IP_ADDR -c 1
	else
		ping -I $INTERFACE $REMOTE_IP_ADDR -c 1
	fi

	ret=$?
}

# Prefix of the file keeping cont. test results
TEST_RESULT_PREFIX="/tmp/cont_board_test."

# Global keeping reference time
REPORT_RESULT_REF_TIME=0

update_test_status()
{
	NAME=$1
	PERIOD=$2
	PASS_NUM=$3
	FAIL_NUM=$4

	TNOW=`date +"%s"`
	TDIFF=$((TNOW - REPORT_RESULT_REF_TIME))
	if [ $TDIFF -ge $PERIOD ]; then
		echo "P: $PASS_NUM F: $FAIL_NUM" > "${TEST_RESULT_PREFIX}${NAME}"
		REPORT_RESULT_REF_TIME=$TNOW
	fi
}

continuous_ping()
{
	INTERFACE=$2
	REMOTE_IP_ADDR=$3

	PASS=0
	FAIL=0

	while true
	do
		single_ping $@
		if [ $ret -ne "0" ]; then
			echo -e "Pinging from $INTERFACE to $REMOTE_IP_ADDR failed\n" >&3
			FAIL=$((FAIL + 1))
		else
			PASS=$((PASS + 1))
		fi
		update_test_status "$INTERFACE" 2 $PASS $FAIL
		sleep 1
	done
}

# pings specified number of times and returns the pass percentage
get_ping_percentage()
{
	PING_COUNT=$4

	PASS_COUNT=0
	for i in $(seq 1 1 $PING_COUNT)
	do
		single_ping $1 $2 $3
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
