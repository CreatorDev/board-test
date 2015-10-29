/**
 * @file
 * test_6lowpan_txrx.c
 *
 * @brief An application for testing 802.15.4 interface on the platform.
 *      It can be run in transmitter or receiver mode. In transmitter mode, it transmits a
 *      specified number of 802.15.4 packets with specified interval. When run as receiver, it
 *      waits for packets arriving on wpan interface and prints the recieved packets. Reception is
 *      disabled in the driver when in transmitter mode and transmission is disabled when in
 *      receiver mode.
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

#include <errno.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <stdbool.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>


#define BASE_HEXADECIMAL        16
#define IEEE802154_ADDR_LEN     8

#define MAX_PACKET_SIZE         (10*1024)

#define MIN_CHANNEL             11
#define MAX_CHANNEL             26

#define DEFAULT_CHANNEL         26
#define DEFAULT_COUNT           50
#define DEFAULT_DELAY_MSEC      100
#define DEFAULT_PAN_ID          0xbeef
#define DEFAULT_INTERFACE       "wpan0"

/* spi32766.0 is based on DTS */
#define DEVICE_SYSFS_PATH       "/sys/bus/spi/devices/spi32766.0"

#define MAX_CMD_SIZE            255
#define MIN_PAYLOAD_LEN         5
#define MAX_PAYLOAD_LEN         105

#define STR_EXPAND(tok)         #tok
#define STR(tok)                STR_EXPAND(tok)

#define ENABLE_DRIVER_RX_MODE() set_driver_mode(1, 0)
#define ENABLE_DRIVER_TX_MODE() set_driver_mode(0, 1)
#define RESTORE_DRIVER_MODE()   set_driver_mode(0, 0)


/* structs defined in net/af_ieee802154.h but not exposed to userspace */
enum {
    IEEE802154_ADDR_NONE = 0x0,
    IEEE802154_ADDR_SHORT = 0x2,
    IEEE802154_ADDR_LONG = 0x3,
};

struct ieee802154_addr_sa {
    int addr_type;
    uint16_t pan_id;
    union {
        uint8_t hwaddr[IEEE802154_ADDR_LEN];
        uint16_t short_addr;
    };
};

struct sockaddr_ieee802154 {
    sa_family_t family;
    struct ieee802154_addr_sa addr;
};

/* Commandline options */
typedef struct command_line_options {
    unsigned channel;
    unsigned short panid;
    unsigned tx_packet_count;
    unsigned tx_size;
    unsigned delay;
    bool tx_mode;
    bool rx_mode;
    bool verbose;
} cmdline_opts;


static bool signal_rcvd = false;

/* Signal handler */
static void signalhandler(int sig)
{
    signal_rcvd = true;
    signal(sig, SIG_IGN);
}

static void usage(const char *name)
{
    printf("Usage:\t %s [options]\n\n"
           "\t[options]\n"
           "\t-f 6lowpan channel to use [11-26]\n"
           "\t-p panid to be used e.g -p 0xabcd\n"
           "\t-t tx mode\n"
           "\t-c number of packets to send in tx mode\n"
           "\t-s packet data length\n"
           "\t-d msec delay between packets in tx mode\n"
           "\t-r rx mode, Press Ctrl+c to exit\n"
           "\t-v verbose, prints rcvd packets\n"
           "\t-h print this message\n",
           name);
}

static bool set_channel_panid(unsigned int channel, unsigned short panid)
{
    char *channel_command_str = "iwpan phy phy0 set channel 0 %u";
    char *panid_command_str = "iwpan dev "DEFAULT_INTERFACE" set pan_id 0x%x";
    char command[MAX_CMD_SIZE];

    /* for setting pan interface has to made down */
    if (system("ifconfig wpan0 down") == 0)
    {
        sprintf(command, channel_command_str, channel);
        if(system(command) != 0)
        {
            return false;
        }
        sprintf(command, panid_command_str, panid);
        if(system(command) != 0)
        {
            return false;
        }
        return (system("ifconfig wpan0 up") == 0);
    }
    return false;
}

static bool set_driver_mode(bool disable_tx, bool disable_rx)
{
    char *ifup_command = "ifconfig "DEFAULT_INTERFACE" up";
    char *ifdown_command = "ifconfig "DEFAULT_INTERFACE" down";
    char rx_command[MAX_CMD_SIZE], tx_command[MAX_CMD_SIZE];

    sprintf(tx_command, "echo %d > "DEVICE_SYSFS_PATH"/disable_tx", disable_tx);
    sprintf(rx_command, "echo %d > "DEVICE_SYSFS_PATH"/disable_rx", disable_rx);

    return ((system(ifdown_command) == 0) &&
            (system(tx_command) == 0) &&
            (system(rx_command) == 0) &&
            (system(ifup_command) == 0));
}

static int start_transmitter(int sd, unsigned panid, unsigned delay,
                              unsigned tx_size, unsigned tx_packet_count)
{
    int ret = 0;
    unsigned i;

    struct sockaddr_ieee802154 dest;
    char *tx_msg = malloc(tx_size);
    if(tx_msg == NULL)
    {
        return -1;
    }

    for (i = 0; i < tx_size; i++)
    {
        tx_msg[i] = i & 0xFF;
    }

    dest.family = AF_IEEE802154;
    dest.addr.pan_id = panid;
    dest.addr.addr_type = IEEE802154_ADDR_SHORT;
    dest.addr.short_addr = 0xFFFF;/* broadcast packet */

    /* send the specified number of packets */
    for (i = 0; i < tx_packet_count && !signal_rcvd; i++)
    {
        ret = sendto(sd, tx_msg, tx_size, 0, (struct sockaddr*) &dest, sizeof(dest));
        if (ret < 0)
        {
            printf("sendto() failed! (%d)", ret);
            break;
        }
        printf("Sent %02u packets\r", i+1);
        fflush(stdout);
        usleep(delay*1000);
    }
    printf("\n");
    free(tx_msg);
    if (ret > 0)
        ret = 0;
    return ret;
}

static int start_receiver(int sd, int verbose)
{
    struct timeval tv;
    fd_set rfds;
    struct sockaddr_ieee802154 src;
    socklen_t addrlen;
    unsigned char rx_buffer[MAX_PACKET_SIZE];
    unsigned i, rx_packet_count;
    int ret = 0;

    while (!signal_rcvd)
    {
        FD_ZERO(&rfds);
        FD_SET(sd, &rfds);
        /* Every one second check if user wants to stop the rx mode */
        tv.tv_sec = 1;
        tv.tv_usec = 0;
        ret = select(sd+1, &rfds, NULL, NULL, &tv);
        if (ret == -1)
        {
            break;
        }
        else if (ret)
        {
            /* Receive a packet */
            ret = recvfrom(sd, rx_buffer, MAX_PACKET_SIZE, 0, (struct sockaddr*)&src , &addrlen);
            if (ret < 0)
            {
                printf("Receive error\n");
                break;
            }
            rx_packet_count++;
            /* Print complete packet only in verbose mode */
            if (verbose)
            {
                printf("Packet %02u: src pan:0x%x addr",
                       rx_packet_count, src.addr.pan_id);

                for (i = 0; i < 8; i++)
                {
                    printf(":%02x", src.addr.hwaddr[i]);
                }
                printf("\nReceived packet:\n");
                for (i = 0; i < ret; i++)
                {
                    printf("%02x ",rx_buffer[i]);
                    if (i != 0 && (i+1) % 16 == 0)
                        printf("\n");
                }
                printf("\n");
            }
            else
            {
                printf("Received %02u packets\r", rx_packet_count);
                fflush(stdout);
            }
        }
    }
    printf("Received %02u packets\n", rx_packet_count);
    return ret;
}

static int create_802154_socket(unsigned short panid)
{
    int sd, ret;
    struct ifreq buffer;
    unsigned i;
    if ((sd = socket(PF_IEEE802154, SOCK_DGRAM, 0)) < 0)
    {
        printf("socket creation failed\n");
        return -1;
    }

    /* bind to the default interface */
    memset(&buffer, 0x00, sizeof(buffer));
    strcpy(buffer.ifr_name, DEFAULT_INTERFACE);
    if (ioctl(sd, SIOCGIFHWADDR, &buffer) != 0)
    {
        printf("get hwaddr failed\n");
        close(sd);
        return -1;
    }

    struct sockaddr_ieee802154 sock_addr;
    sock_addr.family = PF_IEEE802154;
    sock_addr.addr.pan_id = panid;
    sock_addr.addr.addr_type = IEEE802154_ADDR_LONG;
    for( i = 0; i < IEEE802154_ADDR_LEN; i++ )
    {
        sock_addr.addr.hwaddr[i] = buffer.ifr_hwaddr.sa_data[i];
    }

    ret = bind(sd, (struct sockaddr *)&sock_addr, sizeof(sock_addr));
    if (ret)
    {
        printf("bind failed\n");
        close(sd);
        return -1;
    }
    return sd;
}

static int parse_commandline_options(int argc, char **argv, cmdline_opts *opts)
{
    int opt;
    opterr = 0;
    while ((opt = getopt(argc, argv, "trvc:s:d:f:p:h")) != -1)
    {
        switch (opt)
        {
            case 'f':
                opts->channel = atoi(optarg);
                if (opts->channel < MIN_CHANNEL ||
                    opts->channel > MAX_CHANNEL)
                {
                    printf("Invalid 6lowpan channel\n");
                    return -1;
                }
                break;
            case 'p':
                opts->panid = strtoul(optarg, NULL, BASE_HEXADECIMAL);
                if (opts->panid == 0)
                {
                    printf("Invalid panid\n");
                    return -1;
                }
                break;
            case 't':
                opts->tx_mode = true;
                break;
            case 'r':
                opts->rx_mode = true;
                break;
            case 'c':
                opts->tx_packet_count = atoi(optarg);
                if (opts->tx_packet_count == 0)
                {
                    printf("Invalid tx_packet_count\n");
                    return -1;
                }
                break;
            case 's':
                opts->tx_size = atoi(optarg);
                if (opts->tx_size < MIN_PAYLOAD_LEN ||
                    opts->tx_size > MAX_PAYLOAD_LEN)
                {
                    printf("Specify size between " STR(MIN_PAYLOAD_LEN) \
                           " and " STR(MAX_PAYLOAD_LEN) ", both inclusive\n");
                    return -1;
                }
                break;
            case 'd':
                opts->delay = atoi(optarg);
                break;
            case 'v':
                opts->verbose = true;
                break;
            case 'h':
                usage(argv[0]);
                return 0;
            default:
                usage(argv[0]);
                return -1;
        }
    }

    /* if user gives both -r and -t option */
    if (opts->tx_mode && opts->rx_mode)
    {
        printf("Specify either tx or rx mode of operation\n");
        return -1;
    }
    else if (!opts->tx_mode && !opts->rx_mode)
    {
        /* Default tx mode */
        opts->tx_mode = true;
    }
    return 1;
}

int main(int argc, char **argv)
{
    int sd, ret = 0;
    cmdline_opts opts = {
        .channel = DEFAULT_CHANNEL,
        .panid = DEFAULT_PAN_ID,
        .tx_packet_count = DEFAULT_COUNT,
        .tx_size = MIN_PAYLOAD_LEN,
        .delay = DEFAULT_DELAY_MSEC,
        .tx_mode = false,
        .rx_mode = false,
        .verbose = false
    };

    /* register signal handler so that user can stop the operations in between */
    signal(SIGINT, signalhandler);

    /* Parse commandline options */
    ret = parse_commandline_options(argc, argv, &opts);
    if (ret <= 0)
        return ret;

    /* change 6lowpan channel */
    if(!set_channel_panid(opts.channel, opts.panid))
    {
        printf("Setting channel, panid failed\n");
        return -1;
    }

    /* put driver in specified mode    */
    if (opts.tx_mode)
    {
        if(!ENABLE_DRIVER_TX_MODE())
        {
            printf("Setting driver tx mode failed\n");
            return -1;
        }
    }
    else
    {
        if(!ENABLE_DRIVER_RX_MODE())
        {
            printf("Setting driver rx mode failed\n");
            return -1;
        }
    }

    /* Setup 802154 socket */
    if((sd = create_802154_socket(opts.panid)) < 0)
    {
        if(!RESTORE_DRIVER_MODE())
            printf("Restoring driver mode failed\n");
        return -1;
    }

    printf ("channel = %u, panid = 0x%x\n", opts.channel, opts.panid);
    if (opts.tx_mode)
    {
        /* In transmitter mode */
        ret = start_transmitter(sd, opts.panid, opts.delay, opts.tx_size,
                          opts.tx_packet_count);
    }
    else
    {
        /* In receiver mode */
        ret = start_receiver(sd, opts.verbose);
    }

    /* restore the driver mode so that any other applications don't have any issue, though channel,
    *  panid change is not restored
    */
    if(!RESTORE_DRIVER_MODE())
        printf("Restoring driver mode failed\n");

    close(sd);
    return ret;
}

