/**
 * @file
 * test_click_read_thermo3.c
 *
 * @brief An application testing Thermo3 Click.
 *      The test uses I2C to read data from the Click, converts it to
 *      temperature in celsius and prints out to the standard output.
 *      The "-m <mikroBUS>" option specifies mikroBUS where Click sits.
 *
 * @author Imagination Technologies
 *
 * @copyright <b>Copyright 2015 by Imagination Technologies Limited and/or its affiliated group companies.</b>
 *      All rights reserved.  No part of this software, either
 *      material or conceptual may be copied or distributed,
 *      transmitted, transcribed, stored in a retrieval system
 *      or translated into any human or computer language in any
 *      form by any means, electronic, mechanical, manual or
 *      other-wise, or disclosed to the third parties without the
 *      express written permission of Imagination Technologies
 *      Limited, Home Park Estate, Kings Langley, Hertfordshire,
 *      WD4 8LZ, U.K.
 */

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <linux/i2c-dev.h>
#include <string.h>

#define MIKROBUS1_I2C_PATH "/dev/i2c-0"
#define MIKROBUS2_I2C_PATH "/dev/i2c-1"

#define CELSIUS_PER_LSB 0.0625

static int mikrobus_i2c_init(const char *i2c_path)
{
    int fd;
    int address = 0x48;

    if ((fd = open(i2c_path, O_RDWR)) == -1) {
        perror("I2C error: can't open device");
        return -1;
    }
    if (ioctl(fd, I2C_SLAVE, address) < 0) {
        perror("I2C error: ioctl I2C_SLAVE error");
        return -1;
    }

    return fd;
}

typedef struct cmdOpts cmdOpts;
struct cmdOpts {
    const char *i2c_path;
};

static void print_usage(const char *program)
{
    printf("Usage: %s [options]\n\n"
           " -m select mikroBUS where Thermo3 sits (1 or 2)\n"
           " -h display this message\n\n",
            program);
}

static int parse_cmd_opts(int argc, char *argv[], cmdOpts *cmd_opts)
{
    int opt;
    opterr = 0;

    /* default values */
    cmd_opts->i2c_path = MIKROBUS2_I2C_PATH;

    while (1) {
        int tmp;
        opt = getopt(argc, argv, "m:");
        if (opt == -1) {
            break;
        }

        switch (opt) {
        case 'm':
            tmp = strtoul(optarg, NULL, 0);
            if (tmp == 1) {
                cmd_opts->i2c_path = MIKROBUS1_I2C_PATH;
            } else if (tmp == 2) {
                cmd_opts->i2c_path = MIKROBUS2_I2C_PATH;
            } else {
                printf("Error: valid mikroBUS: 1 or 2\n");
                return -1;
            }
            break;
        case 'h':
            print_usage(argv[0]);
            return 0;
        default:
            print_usage(argv[0]);
            return -1;
        }
    }

    return 1;
}

static inline void mikrobus_i2c_free(int fd)
{
    close(fd);
}

static int thermo3_read_data(int fd, float *temperature)
{
    uint8_t buf[2] = {0};
    uint32_t tmp;

    if (read(fd, &buf, 2) == -1) {
        perror("I2C error: can't read data\n");
        return -1;
    }

    *temperature = ((((uint32_t)buf[0] << 8) | buf[1]) >> 4) * CELSIUS_PER_LSB;

    return 0;
}

int main(int argc, char *argv[])
{
    int fd, ret;
    float temperature;
    cmdOpts cmd_opts;

    ret = parse_cmd_opts(argc, argv, &cmd_opts);
    if (ret <= 0) {
        return ret;
    }

    fd = mikrobus_i2c_init(cmd_opts.i2c_path);
    if (fd < 0) {
        return -1;
    }

    ret = thermo3_read_data(fd, &temperature);
    if (ret < 0) {
        return ret;
    }

    printf("%.2f\n", temperature);

    mikrobus_i2c_free(fd);
    return ret;
}
