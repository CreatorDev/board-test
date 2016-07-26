/**
 * @file
 * test_click_access_proximity.c
 *
 * @brief An application testing Proximity Click.
 *      The test communicates via I2C with Proximity Click. Provides basic
 *      set of operations like enable, read proximity and disable.
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
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <string.h>
#include "../log.h"

#define MIKROBUS1_I2C_PATH "/dev/i2c-0"
#define MIKROBUS2_I2C_PATH "/dev/i2c-1"

/* Values based on VCNL4010 manual */

#define DEVICE_I2C_ADDR 0x13

#define REG(i) (0x80 + i)
#define COMMAND_REG  REG(0)
#define PRIDREV_REG  REG(1)
#define PROXRATE_REG REG(2)
#define LED_REG      REG(3)
#define PROX_RESULT_HIGH_REG REG(7)
#define PROX_RESULT_LOW_REG REG(8)

#define COMMAND_SELFTIMED_EN 1
#define COMMAND_PROX_EN 2

/* Configuration */
#define PROXIMITY_RATE 1 /* 3.90625 measurements per second */
#define LED_CURRENT 4 /* 40mA */

FILE *debug_stream = NULL;
int log_level = LOG_INFO;
bool color_logs = false;

static int mikrobus_i2c_init(const char *i2c_path)
{
    int fd;

    if ((fd = open(i2c_path, O_RDWR)) < 0) {
        perror("I2C error: can't open device");
        return -1;
    }
    if (ioctl(fd, I2C_SLAVE, DEVICE_I2C_ADDR) < 0) {
        perror("I2C error: ioctl I2C_SLAVE error");
        return -1;
    }

    return fd;
}

typedef enum AccessType AccessType;
enum AccessType {
    AT_ENABLE = 0,
    AT_DISABLE,
    AT_READ_PROXIMITY
};

typedef struct cmdOpts cmdOpts;
struct cmdOpts {
    AccessType access;
    const char *i2c_path;
};

static void print_usage(const char *program)
{
    LOG(LOG_INFO, "Usage: %s [options]\n\n"
        " -a [edp]\n"
        "    e enable periodic measurements\n"
        "    d disable periodic measurements\n"
        "    p proximity read\n"
        " -m select mikroBUS where Proximity sits (1 or 2)\n"
        " -h display this message\n\n",
        program);
}

static int parse_cmd_opts(int argc, char *argv[], cmdOpts *cmd_opts)
{
    int opt;
    const char *subopt;
    opterr = 0;

    /* default values */
    cmd_opts->i2c_path = MIKROBUS2_I2C_PATH;
    cmd_opts->access = AT_READ_PROXIMITY;

    while (1) {
        int tmp;
        opt = getopt(argc, argv, "a:m:");
        if (opt == -1) {
            break;
        }

        switch (opt) {
        case 'a':
            subopt = optarg;
            switch (subopt[0]) {
            case 'e':
                cmd_opts->access = AT_ENABLE;
                break;
            case 'd':
                cmd_opts->access = AT_DISABLE;
                break;
            case 'p':
                cmd_opts->access = AT_READ_PROXIMITY;
                break;
            default:
                print_usage(argv[0]);
                return -1;
            }
            break;
        case 'm':
            tmp = strtoul(optarg, NULL, 0);
            if (tmp == 1) {
                cmd_opts->i2c_path = MIKROBUS1_I2C_PATH;
            } else if (tmp == 2) {
                cmd_opts->i2c_path = MIKROBUS2_I2C_PATH;
            } else {
                LOG(LOG_ERR, "Error: valid mikroBUS: 1 or 2");
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

static int read_register(int fd, int reg, uint8_t *data)
{
    struct i2c_rdwr_ioctl_data i2c_rdwr;
    struct i2c_msg msg[2];
    uint8_t reg_buf = reg;

    i2c_rdwr.msgs = msg;
    i2c_rdwr.nmsgs = 2;

    /* register address */
    i2c_rdwr.msgs[0].addr = DEVICE_I2C_ADDR;
    i2c_rdwr.msgs[0].len = 1;
    i2c_rdwr.msgs[0].flags = 0;
    i2c_rdwr.msgs[0].buf = &reg_buf;

    /* read one byte */
    i2c_rdwr.msgs[1].addr = DEVICE_I2C_ADDR;
    i2c_rdwr.msgs[1].len = 1;
    i2c_rdwr.msgs[1].flags = I2C_M_RD;
    i2c_rdwr.msgs[1].buf = data;

    if (ioctl(fd, I2C_RDWR, &i2c_rdwr) < 0) {
        perror("I2C error: ioctl I2C_RDWR failed\n");
        return -1;
    }

    return 0;
}

static int write_register(int fd, int reg, uint8_t data)
{
    struct i2c_rdwr_ioctl_data i2c_rdwr;
    struct i2c_msg msg;
    uint8_t buf[2];
    buf[0] = reg;
    buf[1] = data;

    i2c_rdwr.msgs = &msg;
    i2c_rdwr.nmsgs = 1;

    /* one message consisting of 2 writes (register address and data) */
    i2c_rdwr.msgs[0].addr = DEVICE_I2C_ADDR;
    i2c_rdwr.msgs[0].len = 2;
    i2c_rdwr.msgs[0].flags = 0;
    i2c_rdwr.msgs[0].buf = &buf[0];

    if (ioctl(fd, I2C_RDWR, &i2c_rdwr) < 0) {
        perror("I2C error: ioctl I2C_RDWR failed\n");
        return -1;
    }

    return 0;
}

static int proximity_enable(int fd)
{
    /* Set proximity rate to ~4 measurements per second */
    if (write_register(fd, PROXRATE_REG, PROXIMITY_RATE) < 0) {
        return -1;
    }

    /* Set LED to 40mA */
    if (write_register(fd, LED_REG, LED_CURRENT) < 0) {
        return -1;
    }

    /* Enable periodic proximity measurements */
    if (write_register(fd, COMMAND_REG,
                       COMMAND_SELFTIMED_EN | COMMAND_PROX_EN) < 0) {
        return -1;
    }

    return 0;
}

static int proximity_disable(int fd)
{
    /* Disable periodic measurements */
    if (write_register(fd, COMMAND_REG, 0) < 0) {
        return -1;
    }

    return 0;
}

static int proximity_read(int fd, uint32_t *prox)
{
    uint8_t buf[2];

    if (read_register(fd, PROX_RESULT_LOW_REG, &buf[0]) < 0) {
        LOG(LOG_ERR, "I2C error: failed to read proximity result low");
        return -1;
    }

    if (read_register(fd, PROX_RESULT_HIGH_REG, &buf[1]) < 0) {
        LOG(LOG_ERR, "I2C error: failed to read proximity result high");
        return -1;
    }

    *prox = ((uint32_t)buf[1] << 8) | buf[0];

    return 0;
}

int main(int argc, char *argv[])
{
    int fd, ret;
    uint32_t prox;
    cmdOpts cmd_opts;
    debug_stream = stdout;

    ret = parse_cmd_opts(argc, argv, &cmd_opts);
    if (ret <= 0) {
        return ret;
    }

    fd = mikrobus_i2c_init(cmd_opts.i2c_path);
    if (fd < 0) {
        return -1;
    }

    switch (cmd_opts.access) {
    case AT_ENABLE:
        ret = proximity_enable(fd);
        if (ret < 0) {
            break;
        }
        LOG(LOG_INFO, "Proximity periodic measurements have been enabled");
        break;
    case AT_DISABLE:
        ret = proximity_disable(fd);
        if (ret < 0) {
            break;
        }
        LOG(LOG_INFO, "Periodic measurements have been disabled");
        break;
    case AT_READ_PROXIMITY:
        ret = proximity_read(fd, &prox);
        if (ret < 0) {
            break;
        }
        LOG(LOG_INFO, "%d", prox);
        break;
    }

    mikrobus_i2c_free(fd);
    return ret;
}
