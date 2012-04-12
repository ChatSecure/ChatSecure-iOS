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

#ifdef __x86_64__

// 64-bit
typedef uint64_t plframe_pdef_greg_t;
typedef uint64_t plframe_pdef_fpreg_t;

// Data we'll read off the stack frame
#define PLFRAME_PDEF_STACKFRAME_LEN 2

/**
 * @internal
 * x86-64 Registers
 */
typedef enum {
    /*
     * General
     */
    
    /** First return register. */
    PLFRAME_X86_64_RAX = 0,

    /** Local register variable. */
    PLFRAME_X86_64_RBX,

    /** Fourth integer function argument. */
    PLFRAME_X86_64_RCX,

    /** Third function argument. Second return register. */
    PLFRAME_X86_64_RDX,

    /** First function argument. */
    PLFRAME_X86_64_RDI,

    /** Second function argument. */
    PLFRAME_X86_64_RSI,

    /** Optional stack frame pointer. */
    PLFRAME_X86_64_RBP,

    /** Stack pointer. */
    PLFRAME_X86_64_RSP,

    /** Temporary register. */
    PLFRAME_X86_64_R10,

    /** Callee-saved register. */
    PLFRAME_X86_64_R11,

    /** Callee-saved register. */
    PLFRAME_X86_64_R12,

    /** Callee-saved register. */
    PLFRAME_X86_64_R13,

    /** Callee-saved register. */
    PLFRAME_X86_64_R14,    

    /** Callee-saved register. */
    PLFRAME_X86_64_R15,

    /** Instruction pointer */
    PLFRAME_X86_64_RIP,

    /** Flags */
    PLFRAME_X86_64_RFLAGS,

    /*
     * Segment Registers
     */

    /** Segment register */
    PLFRAME_X86_64_CS,

    /** Segment register */
    PLFRAME_X86_64_FS,

    /** Segment register */
    PLFRAME_X86_64_GS,

    PLFRAME_PDEF_REG_IP = PLFRAME_X86_64_RIP,

    /** Last register */
    PLFRAME_PDEF_LAST_REG = PLFRAME_X86_64_GS
} plframe_x86_64_regnum_t;

#endif /* __x86_64__ */
