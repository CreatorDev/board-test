/**
 * @file
 * spi_common.c
 *
 * @brief Common piece of code to communicate to click boards via SPI.
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

#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <string.h>
#include <linux/spi/spidev.h>
#include "spi_common.h"

#define READ_BIT                (0x80)

int spi_init(const char *spi_path)
{
    int fd;
    uint8_t bits_per_word = 8;
    uint32_t mode = SPI_MODE_3;
    uint32_t speed = 1000000;

    if ((fd = open(spi_path, O_NONBLOCK)) == -1) {
        perror("SPI error: can't open device");
        return -1;
    }
    if (ioctl(fd, SPI_IOC_WR_MODE, &mode) == -1) {
        perror("SPI error: can't set mode");
        return -1;
    }
    if (ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits_per_word) == -1) {
        perror("SPI error: can't set bits per word");
        return -1;
    }

    if (ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) == -1) {
        perror("SPI error: can't set max speed HZ");
        return -1;
    }

    return fd;
}

inline void spi_free(int fd)
{
    close(fd);
}

int spi_transfer(int fd,
                          const uint8_t *tx_buffer,
                          uint8_t *rx_buffer,
                          uint32_t count)
{
    struct spi_ioc_transfer tr = {
        .tx_buf = (const unsigned long)&tx_buffer[0],
        .rx_buf = (unsigned long)&rx_buffer[0],
        .len = count
    };

    if (ioctl(fd, SPI_IOC_MESSAGE(1), &tr) < 0) {
        perror("SPI error: can't send data\n");
        return -1;
    }

    return count;
}

uint8_t spi_read_register(int fd, uint8_t reg_address)
{
    uint8_t tx_buffer[2], rx_buffer[2];

    tx_buffer[0] = READ_BIT | reg_address;
    tx_buffer[1] = 0;
    if (spi_transfer(fd, tx_buffer, rx_buffer, 2) < 0) {
        perror("SPI error: can't send data\n");
        return -1;
    }

    return rx_buffer[1];
}

