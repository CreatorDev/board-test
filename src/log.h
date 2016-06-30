/***************************************************************************************************
 * Copyright (c) 2016, Imagination Technologies Limited and/or its affiliated group companies
 * and/or licensors
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *    and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *    endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @file log.h
 * @brief Header file for logging.
 */

#ifndef LOG_H
#define LOG_H

#include <stdio.h>
#include <stdbool.h>

//! \{
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"

#define LOG_FATAL    (1)
#define LOG_ERR      (2)
#define LOG_WARN     (3)
#define LOG_INFO     (4)
#define LOG_DBG      (5)
//! \}

#define SET_COLOR(level)                                  \
    do {                                                  \
        switch (level)                                    \
        {                                                 \
            case LOG_ERR:                                 \
                fprintf(debug_stream, ANSI_COLOR_RED);    \
                break;                                    \
            case LOG_INFO:                                \
                fprintf(debug_stream, ANSI_COLOR_CYAN);   \
                break;                                    \
            default:                                      \
                break;                                    \
        }                                                 \
    } while (0)

#define RESET_COLOR    fprintf(debug_stream, ANSI_COLOR_RESET)

/** Macro for logging message at the specified level. */
#define LOG(level, ...)                                   \
    do {                                                  \
        if (level <= log_level)                           \
        {                                                 \
            if (color_logs == true)                       \
                SET_COLOR(level);                         \
            fprintf(debug_stream, __VA_ARGS__);           \
            fprintf(debug_stream, "\n");                  \
            if (color_logs == true)                       \
                RESET_COLOR;                              \
            fflush(debug_stream);                         \
        }                                                 \
    } while (0)

/** Output stream to dump logs. */
extern FILE *debug_stream;
/** Level for logs. */
extern int log_level;

extern bool color_logs;

#endif  /* LOG_H */
