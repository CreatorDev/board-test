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

#define MIKROBUS1_SPI_PATH "/dev/spidev32766.2"
#define MIKROBUS2_SPI_PATH "/dev/spidev32766.3"


int mikrobus_spi_init(const char *spi_path);

void mikrobus_spi_free(int fd);

uint8_t mikrobus_spi_read_register(int fd, uint8_t reg_address);

#endif
