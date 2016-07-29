/**
 * @file
 * spi_common.h
 *
 * @brief Define common functions used to communicate to click boards via SPI.
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


#ifndef SPI_COMMON_H
#define SPI_COMMON_H

#include <stdint.h>

#define MIKROBUS1_SPI_PATH "/dev/spidev0.2"
#define MIKROBUS2_SPI_PATH "/dev/spidev0.3"

#define SPI_PATH_FOR_MIKROBUS(no) ((no) == 1 ? "/dev/spidev32766.2" : ((no) == 2 ? "/dev/spidev32766.3" : ""))

int spi_init(const char *spi_path);

void spi_free(int fd);

int spi_transfer(int fd, const uint8_t *tx_buffer, uint8_t *rx_buffer, uint32_t count);

uint8_t spi_read_register(int fd, uint8_t reg_address);

#endif
