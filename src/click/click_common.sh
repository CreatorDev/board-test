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

source common.sh

enable_pwm()
{
    MB=$1
    PWM_NUM=$(( MB - 1 ))
    PWM_DIR="/sys/class/pwm/pwmchip0/pwm${PWM_NUM}/"

    if [ ! -d "$PWM_DIR" ]; then
        echo -e "Exporting and enabling pwm on mikroBUS ${MIKROBUS}\n"
        echo $PWM_NUM > /sys/class/pwm/pwmchip0/export
        echo 100000 > "$PWM_DIR/period"
        echo 50000 > "$PWM_DIR/duty_cycle"
        echo 1 > "$PWM_DIR/enable"
    fi
}

enable_i2c_driver()
{
    # Insert i2c_dev driver if not already inserted
    VALUE=`lsmod | grep i2c_dev`
    if [ -z "$VALUE" ]; then
        echo -e "Inserting i2c_dev driver\n"
        modprobe i2c_dev
    fi
}
