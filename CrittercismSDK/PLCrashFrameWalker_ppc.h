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

#ifdef __ppc__

// 32-bit
typedef uintptr_t plframe_pdef_greg_t;
typedef uintptr_t plframe_pdef_fpreg_t;

// Data we'll read off the stack frame
#define PLFRAME_PDEF_STACKFRAME_LEN 3

/**
 * @internal
 * PPC Registers
 */
typedef enum {
    /** Instruction address register (PC) */
    PLFRAME_PPC_SRR0 = 0,
    
    /** Machine state register (supervisor) */
    PLFRAME_PPC_SRR1,
    
    PLFRAME_PPC_DAR,
    PLFRAME_PPC_DSISR,
    
    PLFRAME_PPC_R0,
    PLFRAME_PPC_R1,
    PLFRAME_PPC_R2,
    PLFRAME_PPC_R3,
    PLFRAME_PPC_R4,
    PLFRAME_PPC_R5,
    PLFRAME_PPC_R6,
    PLFRAME_PPC_R7,
    PLFRAME_PPC_R8,
    PLFRAME_PPC_R9,
    PLFRAME_PPC_R10,
    PLFRAME_PPC_R11,
    PLFRAME_PPC_R12,
    PLFRAME_PPC_R13,
    PLFRAME_PPC_R14,
    PLFRAME_PPC_R15,
    PLFRAME_PPC_R16,
    PLFRAME_PPC_R17,
    PLFRAME_PPC_R18,
    PLFRAME_PPC_R19,
    PLFRAME_PPC_R20,
    PLFRAME_PPC_R21,
    PLFRAME_PPC_R22,
    PLFRAME_PPC_R23,
    PLFRAME_PPC_R24,
    PLFRAME_PPC_R25,
    PLFRAME_PPC_R26,
    PLFRAME_PPC_R27,
    PLFRAME_PPC_R28,
    PLFRAME_PPC_R29,
    PLFRAME_PPC_R30,
    PLFRAME_PPC_R31,

    /** Condition register */
    PLFRAME_PPC_CR,
    
    /** User integer exception register */
    PLFRAME_PPC_XER,

    /** Link register */
    PLFRAME_PPC_LR,
    
    /** Count register */
    PLFRAME_PPC_CTR,
    
    /** Vector save reigster */
    PLFRAME_PPC_VRSAVE,

    
    PLFRAME_PDEF_REG_IP = PLFRAME_PPC_SRR0,
    
    /* Last register */
    PLFRAME_PDEF_LAST_REG = PLFRAME_PPC_VRSAVE
} plframe_ppc_regnum_t;

#endif /* __ppc__ */
