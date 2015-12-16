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

# This script will try to run scripts in parallel.

# source any environment variables if set by tester
source ./common.sh

ls ./env.sh &> /dev/null
if [ $? -eq 0 ];then
	source ./env.sh
fi

# killing all processes if they are running
killall test_audio.sh
killall test_heartbeat_led.sh
killall test_sdcard.sh
killall test_ethernet.sh
killall test_6lowpan.sh
killall test_wifi.sh

# starting test scripts in background
./test_audio.sh -d hw:0,2 -c 0 &
sleep 2

./test_heartbeat_led.sh -c 0 &
sleep 2

./test_sdcard.sh -c 0 &
sleep 2

if [ -z ${ETHERNET_PING_HOST} ];then
	./test_ethernet.sh -c 0 &
else
	./test_ethernet.sh -u $ETHERNET_PING_HOST -c 0 &
fi
sleep 2

if [ -z ${WIFI_PING_HOST} ];then
	./test_wifi.sh -c 0 &
else
	./test_wifi.sh -u $WIFI_PING_HOST -c 0 &
fi
sleep 2

./test_6lowpan.sh -c 0 &
sleep 2

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
