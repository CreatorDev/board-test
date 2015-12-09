/**
 * @file
 * test_click_wait_gpio.c
 *
 * @brief An application waiting for an interrupt on selected gpio.
 *      Program assumes that gpio has been already exported and configured as
 *      an interrupt generating input pin (direction = "in", edge = "rising").
 *      User can choose gpio using "-g <gpio number>" option.
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
#include <stdint.h>
#include <string.h>
#include <poll.h>

typedef struct cmdOpts cmdOpts;
struct cmdOpts {
    int timeout; /* timeout in seconds */
    int gpio;
};

static void print_usage(const char *program)
{
    printf("Usage: %s [options]\n\n"
           " -g select GPIO to poll)\n"
           " -t timeout in seconds\n"
           " -h display this message\n\n",
            program);
}

static int parse_cmd_opts(int argc, char *argv[], cmdOpts *cmd_opts)
{
    int opt;
    opterr = 0;

    /* default values */
    cmd_opts->timeout = 5;
    cmd_opts->gpio = 21;

    while (1) {
        opt = getopt(argc, argv, "g:t:");
        if (opt == -1) {
            break;
        }

        switch (opt) {
        case 'g':
            cmd_opts->gpio = strtoul(optarg, NULL, 0);
            if (cmd_opts->gpio == 0) {
                printf("error: provided bad gpio number\n");
                return -1;
            }
            break;
        case 't':
            cmd_opts->timeout = strtoul(optarg, NULL, 0);
            if (cmd_opts->timeout == 0) {
                printf("error: provided bad timeout\n");
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

static int wait_for_interrupt(int gpio, int timeout)
{
    int fd, ret;
    struct pollfd pfd;
    char path[128];
    char buf[8];

    sprintf(path, "/sys/class/gpio/gpio%d/value", gpio);
    if ((fd = open(path, O_RDONLY)) < 0) {
        perror("error: failed to open gpio\n");
        return -1;
    }

    memset(&pfd, 0, sizeof(pfd));
    pfd.fd = fd;
    pfd.events = POLLPRI;

    /* in case there's something pending */
    lseek(pfd.fd, 0, SEEK_SET);
    read(fd, buf, sizeof(buf));

    ret = poll(&pfd, 1, timeout * 1000);

    close(fd);

    return ret;
}

int main(int argc, char *argv[])
{
    int ret;
    cmdOpts cmd_opts;

    ret = parse_cmd_opts(argc, argv, &cmd_opts);
    if (ret <= 0) {
        return ret;
    }

    ret = wait_for_interrupt(cmd_opts.gpio, cmd_opts.timeout);

    if (ret > 0) {
        printf("Interrupt triggered!\n");
    } else if (ret == 0) {
        printf("Timeout.\n");
    } else {
        printf("Error.\n");
    }

    return ret;
}
