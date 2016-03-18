/**
 * @file
 * test_click_read_accel.c
 *
 * @brief An application testing Accel Click.
 *      The test uses SPI to read values from the Accel Click.
 *      The "-m <mikroBUS>" option specifies mikroBUS where Click sits.
 *
 * @author Imagination Technologies
 *
 * @copyright <b>Copyright 2016 by Imagination Technologies Limited and/or its affiliated group companies.</b>
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
#include <stdint.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>
#include <string.h>
#include "spi_common.h"

#define ADXL345_DEVICE_ID       (0xE5)
#define ADXL345_DEVICE_ID_REG   (0x00)

typedef struct cmdOpts cmdOpts;
struct cmdOpts {
    const char *spi_path;
};

static void print_usage(const char *program)
{
    printf("Usage: %s [options]\n\n"
           " -m select mikroBUS where Accel sits (1 or 2, default 1)\n"
           " -h display this message\n\n",
            program);
}

static int parse_cmd_opts(int argc, char *argv[], cmdOpts *cmd_opts)
{
    int opt;
    opterr = 0;

    /* default values */
    cmd_opts->spi_path = MIKROBUS1_SPI_PATH;

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
                cmd_opts->spi_path = MIKROBUS1_SPI_PATH;
            } else if (tmp == 2) {
                cmd_opts->spi_path = MIKROBUS2_SPI_PATH;
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


int main(int argc, char **argv)
{
    int ret, fd;
    cmdOpts cmd_opts;
    ret = parse_cmd_opts(argc, argv, &cmd_opts);

    fd = mikrobus_spi_init(cmd_opts.spi_path);
    if(fd < 0) {
        return fd;
	}

    // Check Device ID
    uint8_t device_id = mikrobus_spi_read_register(fd, ADXL345_DEVICE_ID_REG);
    if(device_id != ADXL345_DEVICE_ID) {
        printf("Error: incorrect device id\n");
        return -1;
    }

    mikrobus_spi_free(fd);

    return 0;
}

