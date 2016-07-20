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
#
# This test implements 16.1 section of GATE Test procedure specifications.


. /usr/lib/board_test_common.sh

NR_ERROR=0

ADC_0_MIN=$1
ADC_0_MAX=$2
ADC_1_MIN=$3
ADC_1_MAX=$4
ADC_2_MIN=$5
ADC_2_MAX=$6
ADC_3_MIN=$7
ADC_3_MAX=$8
ADC_5_MIN=$9
ADC_5_MAX=$10

redirect_output_and_error $LOG_LEVEL

check_adc()
{
    local INDEX=$1
    local ADC_NAME=$2
    local MIN_EXPECTED=$3
    local MAX_EXPECTED=$4
    local VALUE=$(cat /sys/bus/iio/devices/iio:device0/in_voltage${INDEX}_raw)

    if [ $VALUE -lt $MIN_EXPECTED ] || [ $VALUE -gt $MAX_EXPECTED ]; then
        LOG_ERROR "$ADC_NAME has value $VALUE out of valid range [$MIN_EXPECTED, $MAX_EXPECTED]"
        NR_ERROR=$((NR_ERROR + 1))
    else
        LOG_INFO "$ADC_NAME has value $VALUE"
    fi
}

LOG_INFO "16.1.1 MIKRO1_AUXADC"
check_adc 0 "MIKRO1_AUXADC" $ADC_0_MIN $ADC_0_MAX

LOG_INFO "16.1.2 MIKRO2_AUXADC"
check_adc 1 "MIKRO2_AUXADC" $ADC_1_MIN $ADC_1_MAX

LOG_INFO "16.1.3 AUXADC_2"
check_adc 2 "AUXADC_2" $ADC_2_MIN $ADC_2_MAX

LOG_INFO "16.1.4 AUXADC_3"
check_adc 3 "AUXADC_3" $ADC_3_MIN $ADC_3_MAX

LOG_INFO "16.1.5 AUXADC_5"
check_adc 5 "AUXADC_5" $ADC_5_MIN $ADC_5_MAX

exit $NR_ERROR
