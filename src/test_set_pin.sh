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

# can be used for setting state of GPIO only if it can be exported from user space
# ensure that MFIO number is correct

LOG_LEVEL=1
source common.sh
redirect_output_and_error $LOG_LEVEL

Usage() {
	echo -e "Usage: Give argument as MFIO number and its value (1 or 0)  e.g. ./set_pin.sh 76 1\n"  >&3
}

if [ "$#" -lt 2 ];then
	Usage
	exit 1
fi

MFIO=$1
VALUE=$2

# check if value is either 1 or 0
if [ $VALUE -ne 1 ] && [ $VALUE -ne 0 ];then
	Usage
	exit 1
fi

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
	# set pin direction as output
	DIRECTION=`cat /sys/class/gpio/gpio$MFIO/direction`
	if [ "$DIRECTION" != "out" ]; then
		echo out > /sys/class/gpio/gpio$MFIO/direction
	fi

	#set value
	echo $VALUE > /sys/class/gpio/gpio$MFIO/value
}>&3

