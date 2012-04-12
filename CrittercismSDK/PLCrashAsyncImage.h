/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2011 Plausible Labs Cooperative, Inc.
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

#include <stdint.h>
#include <libkern/OSAtomic.h>
#include <stdbool.h>

/**
 * @internal
 * @ingroup plcrash_async_image
 *
 * Async-safe binary image list element.
 */
typedef struct plcrash_async_image {
    /** The binary image's header address. */
    uintptr_t header;
    
    /** The binary image's name/path. */
    char *name;

    /** The previous image in the list, or NULL */
    struct plcrash_async_image *prev;
    
    /** The next image in the list, or NULL. */
    struct plcrash_async_image *next;
} plcrash_async_image_t;

/**
 * @internal
 * @ingroup plcrash_async_image
 *
 * Async-safe binary image list. May be used to iterate over the binary images currently
 * available in-process.
 */
typedef struct plcrash_async_image_list {
    /** The lock used by writers. No lock is required for readers. */
    OSSpinLock write_lock;

    /** The head of the list, or NULL if the list is empty. Must only be used to iterate or delete entries. */
    plcrash_async_image_t *head;

    /** The tail of the list, or NULL if the list is empty. Must only be used to append new entries. */
    plcrash_async_image_t *tail;

    /** The list reference count. No nodes will be deallocated while the count is greater than 0. If the count
     * reaches 0, all nodes in the free list will be deallocated. */
    int32_t refcount;

    /** The node free list. */
    plcrash_async_image_t *free;
} plcrash_async_image_list_t;

void plcrash_async_image_list_init (plcrash_async_image_list_t *list);
void plcrash_async_image_list_free (plcrash_async_image_list_t *list);
void plcrash_async_image_list_append (plcrash_async_image_list_t *list, uintptr_t header, const char *name);
void plcrash_async_image_list_remove (plcrash_async_image_list_t *list, uintptr_t header);

void plcrash_async_image_list_set_reading (plcrash_async_image_list_t *list, bool enable);
plcrash_async_image_t *plcrash_async_image_list_next (plcrash_async_image_list_t *list, plcrash_async_image_t *current);
