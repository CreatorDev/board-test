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

. /usr/lib/board_test_common.sh

enable_pwm()
{
	MB=$1
	PWM_NUM=$(( MB - 1 ))
	PWM_DIR="/sys/class/pwm/pwmchip0/pwm${PWM_NUM}/"

	if [ ! -d "$PWM_DIR" ]; then
		LOG_INFO "Exporting and enabling pwm on mikroBUS ${MIKROBUS}\n"
		echo $PWM_NUM > /sys/class/pwm/pwmchip0/export
		echo 100000 > "$PWM_DIR/period"
		echo 50000 > "$PWM_DIR/duty_cycle"
		echo 1 > "$PWM_DIR/enable"
	fi
	return $?
}

enable_i2c_driver()
{
	# Insert i2c_dev driver if not already inserted
	lsmod | grep i2c_dev >/dev/null
	if [ $? -ne $SUCCESS ]; then
		LOG_INFO "Inserting i2c_dev driver\n"
		modprobe i2c_dev
		if [ $? -ne $SUCCESS ]; then
			LOG_ERROR "Failed to load i2c_dev driver\n"
			return $FAILURE
		fi
	fi
}
