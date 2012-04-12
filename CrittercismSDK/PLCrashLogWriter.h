/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2010 Plausible Labs Cooperative, Inc.
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

#import <TargetConditionals.h>
#import <Foundation/Foundation.h>

#import "PLCrashAsync.h"
#import "PLCrashAsyncImage.h"

/**
 * @internal
 * @defgroup plcrash_log_writer Crash Log Writer
 * @ingroup plcrash_internal
 *
 * Implements an async-safe, zero allocation crash log writer C API, intended
 * to be called from the crash log signal handler.
 *
 * @{
 */

/**
 * @internal
 *
 * Crash log writer context.
 */
typedef struct plcrash_log_writer {
    /** System data */
    struct {
        /** The host OS version. */
        char *version;

        /** The host OS build number. This may be NULL. */
        char *build;
    } system_info;

    /* Machine data */
    struct {
        /** The host model (may be NULL). */
        char *model;

        /** The host CPU type. */
        uint64_t cpu_type;

        /** The host CPU subtype. */
        uint64_t cpu_subtype;
        
        /** The total number of physical cores */
        uint32_t processor_count;
        
        /** The total number of logical cores */
        uint32_t logical_processor_count;
    } machine_info;

    /** Application data */
    struct {
        /** Application identifier */
        char *app_identifier;

        /** Application version */
        char *app_version;
    } application_info;
    
    /** Process data */
    struct {
        /** Process name (may be null) */
        char *process_name;
        
        /** Process ID */
        pid_t process_id;
        
        /** Process path (may be null) */
        char *process_path;
        
        /** Parent process name (may be null) */
        char *parent_process_name;
        
        /** Parent process ID */
        pid_t parent_process_id;
        
        /** If false, the reporting process is being run under process emulation (such as Rosetta). */
        bool native;
    } process_info;
    
    /** Binary image data */
    struct {
        /** The list of the processes' loaded images, as provided by dyld. */
        plcrash_async_image_list_t image_list;
    } image_info;

    /** Uncaught exception (if any) */
    struct {
        /** Flag specifying wether an uncaught exception is available. */
        bool has_exception;

        /** Exception name (may be null) */
        char *name;

        /** Exception reason (may be null) */
        char *reason;

        /** The original exception call stack (may be null) */
        void **callstack;
        
        /** Call stack frame count, or 0 if the call stack is unavailable */
        size_t callstack_count;
    } uncaught_exception;
} plcrash_log_writer_t;


plcrash_error_t plcrash_log_writer_init (plcrash_log_writer_t *writer, NSString *app_identifier, NSString *app_version);
void plcrash_log_writer_set_exception (plcrash_log_writer_t *writer, NSException *exception);

void plcrash_log_writer_add_image (plcrash_log_writer_t *writer, const void *header_addr);
void plcrash_log_writer_remove_image (plcrash_log_writer_t *writer, const void *header_addr);

plcrash_error_t plcrash_log_writer_write (plcrash_log_writer_t *writer, plcrash_async_file_t *file, siginfo_t *siginfo, ucontext_t *crashctx);
plcrash_error_t plcrash_log_writer_close (plcrash_log_writer_t *writer);
void plcrash_log_writer_free (plcrash_log_writer_t *writer);

/**
 * @} plcrash_log_writer
 */
