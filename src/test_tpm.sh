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

# This test tries to read one register from Infineon chip

. /usr/lib/board_test_common.sh

MARDUK_TPM_RST_MFIO=42

parse_command_line $@

redirect_output_and_error $LOG_LEVEL


LOG_INFO "\n**************************  TPM test **************************\n"

# Set up TPM_RST MFIO
$BOARD_TEST_PATH/test_set_pin.sh $MARDUK_TPM_RST_MFIO 1 >/dev/null

# Insert i2c_dev driver if not already inserted
VALUE=$(lsmod | grep i2c_dev)
if [ -z "$VALUE" ]; then
	LOG_INFO "Inserting i2c_dev driver\n"
	modprobe i2c_dev
	if [ $? -ne $SUCCESS ]; then
		LOG_ERROR "Failed to load i2c_dev driver\n"
		exit $FAILURE
	fi
fi

# DIDVID register address is 0x6 and should read 0x15d1 for SLB9645VQ1.2 chip
VALUE=$(i2cget -y -f 0 0x20 0x6 w)

EXPECTED=0x15d1
if [ "$VALUE" = "$EXPECTED" ]; then
	LOG_INFO "PASS: TPM chip found \n"
else
	LOG_ERROR "FAIL: Read failed \n"
	exit $FAILURE
fi
