#!/bin/sh
#
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


# log levels
ERROR=1
INFO=2
DEBUG=3

# file descriptors
STDIN=0
STDOUT=1
STDERR=2
CUSTOM_STDOUT=3

# colors
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# exit status
SUCCESS=0
FAILURE=1

# default log level
LOG_LEVEL=$INFO

BOARD_TEST_PATH=/usr/bin/board_test

redirect_output_and_error()
{
	case $1 in
		$ERROR | $INFO) exec 3>&1  1>/dev/null  2>/dev/null
			;;
		$DEBUG) exec 3>&1
			;;
	esac
}

LOG_ERROR()
{
	if [ $LOG_LEVEL -ge $ERROR ]; then
		# Use colors only when stdout is connected to the terminal
		if [ -t $CUSTOM_STDOUT ]; then
			echo -e "${RED}$@${NC}" >&$CUSTOM_STDOUT
		else
			echo -e "$@" >&$CUSTOM_STDOUT
		fi
	fi
}

LOG_INFO()
{
	if [ $LOG_LEVEL -ge $INFO ]; then
		# Use colors only when stdout is connected to the terminal
		if [ -t $CUSTOM_STDOUT ]; then
			echo -e "${CYAN}$@${NC}" >&$CUSTOM_STDOUT
		else
			echo -e "$@" >&$CUSTOM_STDOUT
		fi
	fi
}

LOG_DEBUG()
{
	if [ $LOG_LEVEL -ge $DEBUG ]; then
		echo -e "$@" >&$CUSTOM_STDOUT
	fi
}

PROGRESS_BAR()
{
	if [ $LOG_LEVEL -ge $INFO ]; then
		# Use colors only when stdout is connected to the terminal
		if [ -t $CUSTOM_STDOUT ]; then
			printf "${YELLOW}$@" >&$CUSTOM_STDOUT
			printf "${NC}" >&$CUSTOM_STDOUT
		else
			printf "$@" >&$CUSTOM_STDOUT
		fi
	fi
}

QUESTION()
{
	if [ $LOG_LEVEL -ge $INFO ]; then
		# Use colors only when stdout is connected to the terminal
		if [ -t $CUSTOM_STDOUT ]; then
			echo -e "${YELLOW}$@${NC}" >&$CUSTOM_STDOUT
		else
			echo -e "$@" >&$CUSTOM_STDOUT
		fi
	fi
}

reset_color()
{
	echo -e "${NC}" >&$CUSTOM_STDOUT
}

# default cleanup function
cleanup_and_exit()
{
	reset_color
	exit $FAILURE
}

# default signal handler for Ctrl+c
trap cleanup_and_exit INT


USAGE="
Usage: $0 options

OPTIONS:
-h  Show this message
-v  Verbose
-V  Show package version
"

parse_command_line()
{
	while getopts "vVh" opt; do
		case $opt in
			v)
				LOG_LEVEL=$DEBUG
				;;
			V)
				echo "version = "$(cat $BOARD_TEST_PATH/version)
				exit $SUCCESS
				;;
			h)
				echo "${USAGE}"
				exit $SUCCESS
				;;
			\?)
				echo "${USAGE}"
				exit $FAILURE
				;;
		esac
	done
}

single_ping()
{
	local PING_TYPE=$1
	local INTERFACE=$2
	local REMOTE_IP_ADDR=$3
	local PACKET_SIZE=$4

	if [ $PING_TYPE = "ipv6" ]; then
		ping6 -I $INTERFACE $REMOTE_IP_ADDR -c 1 -s $PACKET_SIZE
	elif [ $PING_TYPE = "bt" ]; then
		l2ping $REMOTE_IP_ADDR -c 1 -s $PACKET_SIZE
	else
		ping -I $INTERFACE $REMOTE_IP_ADDR -c 1 -s $PACKET_SIZE
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

	TNOW=$(date +"%s")
	TDIFF=$((TNOW - REPORT_RESULT_REF_TIME))
	if [ $TDIFF -ge $PERIOD ]; then
		echo "P: $PASS_NUM F: $FAIL_NUM" > "${TEST_RESULT_PREFIX}${NAME}"
		REPORT_RESULT_REF_TIME=$TNOW
	fi
}

continuous_ping()
{
	local PING_TYPE=$1
	local INTERFACE=$2
	local REMOTE_IP_ADDR=$3
	local PACKET_SIZE=$4
	local INTERVAL=$5
	local PASS=0
	local FAIL=0

	while true
	do
		single_ping $PING_TYPE $INTERFACE $REMOTE_IP_ADDR $PACKET_SIZE
		if [ $ret -ne "0" ]; then
			LOG_INFO "Pinging from $INTERFACE to $REMOTE_IP_ADDR failed\n"
			FAIL=$((FAIL + 1))
		else
			PASS=$((PASS + 1))
		fi
		update_test_status "$INTERFACE" 2 $PASS $FAIL
		usleep $INTERVAL
	done
}

# pings specified number of times and returns the pass percentage
get_ping_percentage()
{
	local PING_TYPE=$1
	local INTERFACE=$2
	local REMOTE_IP_ADDR=$3
	local PACKET_SIZE=$4
	local PING_COUNT=$5

	local PASS_COUNT=0
	for i in $(seq 1 1 $PING_COUNT)
	do
		single_ping $PING_TYPE $INTERFACE $REMOTE_IP_ADDR $PACKET_SIZE
		if [ $ret -eq "0" ]; then
			PASS_COUNT=$(($PASS_COUNT + 1))
		fi

		PROGRESS_BAR "Progress %3d%%(%2d/%2d) Pass %3d%%(%2d/%2d)\r" $((i*100/PING_COUNT)) \
			$i $PING_COUNT $((PASS_COUNT*100/i)) $PASS_COUNT $i >&$CUSTOM_STDOUT
	done
	echo -e "\n" >&$CUSTOM_STDOUT

	percent=$((PASS_COUNT*100/PING_COUNT))
	return $percent
}

show_result_based_on_switch_pressed()
{
	local SWITCH_TIMEOUT=10
	if [ $# -eq 1 ]; then
		SWITCH_TIMEOUT=$1
	fi

	LOG_INFO "Press switch 1 for pass or switch 2 for fail \n"
	$BOARD_TEST_PATH/test_switch -w -t $SWITCH_TIMEOUT
	case $? in
		1)
			LOG_INFO "PASS"
			return 0
			;;
		2)
			LOG_ERROR "FAIL"
			return 1
			;;
		254)
			LOG_ERROR "FAIL (no key pressed within timeout)"
			return 254
			;;
		255)
			LOG_ERROR "FAIL (some error in reading switches)"
			return 255
			;;
		*)
			LOG_ERROR "FAIL (invalid return code from test_switch)"
			return 253
			;;
	esac
}

show_result_based_on_switch_pressed_and_exit()
{
	show_result_based_on_switch_pressed $@
	exit $?
}

print_result()
{
	TEST_NAME=$1
	TEST_STATUS=$2

	if [ $TEST_STATUS -eq $SUCCESS ]; then
		echo -e "$TEST_NAME: PASS\n"
	else
		echo -e "$TEST_NAME: ${RED}FAIL${NC}\n"
	fi
}

unmount_dir()
{
	MOUNT_DIR=$1
	# Unmount if directory is already mounted
	if mountpoint -q -- $MOUNT_DIR; then
		umount $MOUNT_DIR  &&\
		rm -rf $MOUNT_DIR
	fi
}

check_read_write()
{
	SRC_TEMP_FILE=$1
	DST_TEMP_FILE=$2

	LOG_INFO "Check read write"
	dd if=/dev/urandom of=$SRC_TEMP_FILE bs=1k count=1024  &&\
	cp $SRC_TEMP_FILE $DST_TEMP_FILE                       &&\
	sync                                                   &&\
	cmp $SRC_TEMP_FILE $DST_TEMP_FILE
}
