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

#ifdef __arm__

// 32-bit
typedef uintptr_t plframe_pdef_greg_t;
typedef uintptr_t plframe_pdef_fpreg_t;

// Data we'll read off the stack frame
#define PLFRAME_PDEF_STACKFRAME_LEN 2

/**
 * @internal
 * Arm registers
 */
typedef enum {
    /*
     * General
     */

    PLFRAME_ARM_R0 = 0,
    PLFRAME_ARM_R1,
    PLFRAME_ARM_R2,
    PLFRAME_ARM_R3,
    PLFRAME_ARM_R4,
    PLFRAME_ARM_R5,
    PLFRAME_ARM_R6,
    PLFRAME_ARM_R7,
    PLFRAME_ARM_R8,
    PLFRAME_ARM_R9,
    PLFRAME_ARM_R10,
    PLFRAME_ARM_R11,
    PLFRAME_ARM_R12,

    /* stack pointer (r13) */
    PLFRAME_ARM_SP,

    /* link register (r14) */
    PLFRAME_ARM_LR,

    /** Program counter (r15) */
    PLFRAME_ARM_PC,
    
    /** Current program status register */
    PLFRAME_ARM_CPSR,

    /* Common registers */
    
    PLFRAME_PDEF_REG_IP = PLFRAME_ARM_PC,
    
    /** Last register */
    PLFRAME_PDEF_LAST_REG = PLFRAME_ARM_CPSR
} plframe_arm_regnum_t;

#endif
