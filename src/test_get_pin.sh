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

# can be used for getting state of GPIO only if it can be exported from user space
# ensure that MFIO number is correct

. /usr/lib/board_test_common.sh

redirect_output_and_error $LOG_LEVEL

USAGE="
Usage: Give argument as MFIO number

Example:
	$0 511
"

if [ "$#" -lt 1 ]; then
	LOG_INFO "${USAGE}"
	exit $FAILURE
fi

MFIO=$1

# check if the gpio has already been exported
ls /sys/class/gpio/gpio$MFIO  >/dev/null

if [ $? -ne $SUCCESS ]; then
	{ echo $MFIO > /sys/class/gpio/export } >&$CUSTOM_STDOUT
	if [ $? -ne $SUCCESS ]; then
		LOG_ERROR "Failed to export gpio"
		exit $FAILURE
	fi
fi

{
	# set pin direction as input
	echo in > /sys/class/gpio/gpio$MFIO/direction
	#get value
	cat /sys/class/gpio/gpio$MFIO/value
} >&$CUSTOM_STDOUT
