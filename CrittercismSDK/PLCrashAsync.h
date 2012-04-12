/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2009 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


#import <stdio.h> // for snprintf
#import <unistd.h>
#import <stdbool.h>

// Debug output support. Lines are capped at 128 (stack space is scarce). This implemention
// is not async-safe and should not be enabled in release builds
#ifdef PLCF_RELEASE_BUILD

#define PLCF_DEBUG(msg, args...)

#else

#define PLCF_DEBUG(msg, args...) {\
    char output[128];\
    snprintf(output, sizeof(output), "[PLCrashReport] " msg "\n", ## args); \
    write(STDERR_FILENO, output, strlen(output));\
}

#endif /* PLCF_RELEASE_BUILD */


/**
 * @ingroup plcrash_async
 * Error return codes.
 */
typedef enum  {
    /** Success */
    PLCRASH_ESUCCESS = 0,
    
    /** Unknown error (if found, is a bug) */
    PLCRASH_EUNKNOWN,
    
    /** The output file can not be opened or written to */
    PLCRASH_OUTPUT_ERR,
    
    /** No memory available (allocation failed) */
    PLCRASH_ENOMEM,
    
    /** Unsupported operation */
    PLCRASH_ENOTSUP,
    
    /** Invalid argument */
    PLCRASH_EINVAL,
    
    /** Internal error */
    PLCRASH_EINTERNAL,
} plcrash_error_t;

const char *plcrash_strerror (plcrash_error_t error);

void *plcrash_async_memcpy(void *dest, const void *source, size_t n);

/**
 * @internal
 * @ingroup plcrash_async_bufio
 *
 * Async-safe buffered file output. This implementation is only intended for use
 * within signal handler execution of crash log output.
 */
typedef struct plcrash_async_file {
    /** Output file descriptor */
    int fd;

    /** Output limit */
    off_t limit_bytes;

    /** Total bytes written */
    off_t total_bytes;

    /** Current length of data in buffer */
    size_t buflen;

    /** Buffered output */
    char buffer[256];
} plcrash_async_file_t;


void plcrash_async_file_init (plcrash_async_file_t *file, int fd, off_t output_limit);
bool plcrash_async_file_write (plcrash_async_file_t *file, const void *data, size_t len);
bool plcrash_async_file_flush (plcrash_async_file_t *file);
bool plcrash_async_file_close (plcrash_async_file_t *file);
