/**
 * @file
 * test_click_write_bargraph.c
 *
 * @brief An application testing BarGraph Click.
 *      The test uses SPI to access the display on the BarGraph Click.
 *      It is important to enable PWM before running this program.
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
#include <linux/spi/spidev.h>
#include <sys/ioctl.h>
#include <string.h>
#include <stdbool.h>
#include "spi_common.h"

#define DEMO_ITERATIONS 4
#define DEMO_DELAY 4000


/* bottom 10 bits of display_seg argument correspond to 10 display segments */
static int bargraph_send_to_display(int fd, unsigned int display_seg)
{
    int ret;
    unsigned int buf[2];
    struct spi_ioc_transfer tr[2];

    /* buf[0] will be shifted into segments 8 and 9 */
    buf[0] = (display_seg >> 8) & 3;
    /* buf[1] sets segments 0 to 7 */
    buf[1] = display_seg & 0xff;

    /* send message consisting of two transfers */
    memset(&tr, 0, sizeof(tr));
    tr[0].tx_buf = (unsigned long)&buf[0];
    tr[0].len = 1;
    tr[1].tx_buf = (unsigned long)&buf[1];
    tr[1].len = 1;
    ret = ioctl(fd, SPI_IOC_MESSAGE(2), &tr);

    if (ret == -1) {
        perror("SPI error: can't send data\n");
        return -1;
    }

    return 0;
}

typedef struct cmdOpts cmdOpts;
struct cmdOpts {
    bool run_demo;
    unsigned int display_seg;
    const char *spi_path;
};

static void print_usage(const char *program)
{
    printf("Usage: %s [options]\n\n"
           " -m select mikroBUS where BarGraph sits (1 or 2)\n"
           " -s set BarGraph to a fixed value from 0 to 0x3ff\n"
           " -d run demo\n"
           " -h display this message\n\n",
            program);

    printf(" Example to light up top and bottom 2 segments of BarGraph's display:\n"
           " %s -m 1 -s 0x303\n\n", program);
}

static int parse_cmd_opts(int argc, char *argv[], cmdOpts *cmd_opts)
{
    int opt;
    opterr = 0;

    /* default values */
    cmd_opts->run_demo = false;
    cmd_opts->display_seg = 0;
    cmd_opts->spi_path = MIKROBUS1_SPI_PATH;

    while (1) {
        int tmp;
        opt = getopt(argc, argv, "ds:m:");
        if (opt == -1) {
            break;
        }

        switch (opt) {
        case 'd':
            cmd_opts->run_demo = true;
            break;
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
        case 's':
            tmp = strtoul(optarg, NULL, 0);
            if (tmp >= 0 && tmp <= 0x3ff) {
                cmd_opts->display_seg = tmp;
            } else {
                printf("Error: correct range for the value: 0 - 0x3ff\n");
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

/* Simple demo lighting up display segments sequentially */
static int run_demo(int fd)
{
    int i, j;

    for (j = 0; j < DEMO_ITERATIONS; j++) {
        for (i = 0; i <= 100; i++) {
            if (bargraph_send_to_display(fd, (1 << (i/10)) - 1) < 0) {
                return -1;
            }
            usleep(DEMO_DELAY);
        }

        for (i = 109; i > 0; i--) {
            if (bargraph_send_to_display(fd, (1 << (i/10)) - 1) < 0) {
                return -1;
            }
            usleep(DEMO_DELAY);
        }
    }

    for (i = 0; i <= 100; i++) {
        if (bargraph_send_to_display(fd, (1 << (i/10)) - 1) < 0) {
            return -1;
        }
        usleep(DEMO_DELAY);
    }

    return 0;
}

int main(int argc, char *argv[])
{
    int fd, ret;
    cmdOpts cmd_opts;

    ret = parse_cmd_opts(argc, argv, &cmd_opts);
    if (ret <= 0) {
        return ret;
    }

    fd = mikrobus_spi_init(cmd_opts.spi_path);
    if (fd < 0) {
        return -1;
    }

    if (cmd_opts.run_demo) {
        /* run default demo */
        ret = run_demo(fd);
    } else {
        /* set segments to a fixed value */
        ret = bargraph_send_to_display(fd, cmd_opts.display_seg);
    }

    mikrobus_spi_free(fd);
    return ret;
}
