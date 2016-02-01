#
# Copyright 2016 by Imagination Technologies Limited and/or its affiliated group companies.
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

# This script will try to run scripts in parallel.
# Input arguments specify test list to run. If no arguments are provided
# then running all the tests.
#
# Example to start only Heartbeat and 6LoWPAN tests:
# ./continuous-test-marduk.sh hb 6l

# Test list:
# au - audio
# hb - heartbeat
# sd - SD card
# et - ethernet
# wf - WiFi
# 6l - 6LoWPAN
# tb - thermo3 bargraph
# ac - accel
# pr - proximity

TESTLIST="au hb sd et wf 6l tb ac pr"

# source any environment variables if set by tester
source ./common.sh

ls ./env.sh &> /dev/null
if [ $? -eq 0 ];then
	source ./env.sh
fi

usage()
{
cat << EOF

usage: $0 [options] [tests]
Give input arguments to specify test from following test list to run.
If no arguments are provided then all the tests will be started.

Example to start only Heartbeat and 6LoWPAN tests:
$0 hb 6l

Test list:
au - audio
hb - heartbeat
sd - SD card
et - ethernet
wf - WiFi
6l - 6LoWPAN
tb - thermo3 bargraph
ac - accel
pr - proximity

OPTIONS:
-h	Show this message
-k	Kill all tests which were started by this script earlier
-V	Show package version

EOF
}

kill_all_tests()
{
	# killing all tests if they are running
	killall test_audio.sh
	killall test_heartbeat_led.sh
	killall test_sdcard.sh
	killall test_ethernet.sh
	killall test_6lowpan.sh
	killall test_wifi.sh
	killall test_click_thermo3_to_bargraph.sh
	killall test_click_accel.sh
	killall test_click_proximity.sh
}

kill_all_tests_and_exit()
{
	kill_all_tests
	exit 0
}

# handle Ctrl+c
trap kill_all_tests_and_exit INT

while getopts "kVh" opt; do
	case $opt in
		k)
			kill_all_tests
			exit 0;;
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

kill_all_tests

# Check if provided tests are valid
for testname in "$@"
do
	FOUND=false
	for t in $TESTLIST
	do
		if [ "$testname" == "$t" ]; then
			FOUND=true
			break
		fi
	done
	if (!("$FOUND")); then
		echo "Error! Unknown test: $testname"
		exit 1
	fi
done

# Delete previous test results.
rm /tmp/cont_board_test.*

start_bg_test_au()
{
	./test_audio.sh -d hw:0,2 -c 0 &
	sleep 2
}

start_bg_test_hb()
{
	./test_heartbeat_led.sh -c 0 &
	sleep 2
}

start_bg_test_sd()
{
	./test_sdcard.sh -c 0 &
	sleep 2
}

start_bg_test_et()
{
	if [ -z ${ETHERNET_PING_HOST} ];then
		./test_ethernet.sh -c 0 &
	else
		./test_ethernet.sh -u $ETHERNET_PING_HOST -c 0 &
	fi
	sleep 2
}

start_bg_test_wf()
{
	if [ -z ${WIFI_PING_HOST} ];then
		./test_wifi.sh -c 0 &
	else
		./test_wifi.sh -u $WIFI_PING_HOST -c 0 &
	fi
	sleep 2
}

start_bg_test_6l()
{
	./test_6lowpan.sh -c 0 &
	sleep 2
}

start_bg_test_tb()
{
	./test_click_thermo3_to_bargraph.sh -c 0 &
	sleep 2
}

start_bg_test_ac()
{
	./test_click_accel.sh -c 0 &
	sleep 2
}

start_bg_test_pr()
{
	./test_click_proximity.sh -c 0 &
	sleep 2
}

# Start selected tests
TEST_STARTED=false
for testname in "$@"
do
	start_bg_test_$testname
	TEST_STARTED=true
done

if (!("$TEST_STARTED")); then
	echo "No argument specified, thus running all the tests"
	for t in $TESTLIST
	do
		start_bg_test_$t
	done
fi

# wait until tests start running before printing out results
sleep 30

# print out results every 5 seconds
while sleep 5; do
	for result in "$TEST_RESULT_PREFIX"*; do
		STAT=`cat $result`
		printf "${result#$TEST_RESULT_PREFIX} ${STAT} | "
	done
	printf "\n"
done
