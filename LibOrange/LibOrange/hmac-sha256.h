/*
 * Copyright 2006 Apple Computer, Inc.  All rights reserved.
 * 
 * iTunes U Sample Code License
 * IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") 
 * in consideration of your agreement to the following terms, and your use, 
 * installation, modification or distribution of this Apple software constitutes 
 * acceptance of these terms.  If you do not agree with these terms, please do not use, 
 * install, modify or distribute this Apple software.
 * 
 * In consideration of your agreement to abide by the following terms and subject to
 * these terms, Apple grants you a personal, non-exclusive, non-transferable license, 
 * under Apple's copyrights in this original Apple software (the "Apple Software"): 
 * 
 * (a) to internally use, reproduce, modify and internally distribute the Apple 
 * Software, with or without modifications, in source and binary forms, within your 
 * educational organization or internal campus network for the sole purpose of 
 * integrating Apple's iTunes U software with your internal campus network systems; and 
 * 
 * (b) to redistribute the Apple Software to other universities or educational 
 * organizations, with or without modifications, in source and binary forms, for the 
 * sole purpose of integrating Apple's iTunes U software with their internal campus 
 * network systems; provided that the following conditions are met:
 * 
 * 	-  If you redistribute the Apple Software in its entirety and without 
 *     modifications, you must retain the above copyright notice, this entire license 
 *     and the disclaimer provisions in all such redistributions of the Apple Software.
 * 	-  If you modify and redistribute the Apple Software, you must indicate that you
 *     have made changes to the Apple Software, and you must retain the above
 *     copyright notice, this entire license and the disclaimer provisions in all
 *     such redistributions of the Apple Software and/or derivatives thereof created
 *     by you.
 *     -  Neither the name, trademarks, service marks or logos of Apple may be used to 
 *     endorse or promote products derived from the Apple Software without specific 
 *     prior written permission from Apple.  
 * 
 * Except as expressly stated above, no other rights or licenses, express or implied, 
 * are granted by Apple herein, including but not limited to any patent rights that may
 * be infringed by your derivative works or by other works in which the Apple Software 
 * may be incorporated.  THE APPLE SOFTWARE IS PROVIDED BY APPLE ON AN "AS IS" BASIS.  
 * APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, AND HEREBY DISCLAIMS ALL WARRANTIES, 
 * INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE 
 * OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS OR SYSTEMS.  
 * APPLE IS NOT OBLIGATED TO PROVIDE ANY MAINTENANCE, TECHNICAL OR OTHER SUPPORT FOR 
 * THE APPLE SOFTWARE, OR TO PROVIDE ANY UPDATES TO THE APPLE SOFTWARE.  IN NO EVENT 
 * SHALL APPLE BE LIABLE FOR ANY DIRECT, SPECIAL, INDIRECT, INCIDENTAL OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION 
 * OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT 
 * (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN 
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.         
 * 
 * Rev.  120806												
 *
 * This source code file contains a self-contained ANSI C program with no
 * external dependencies except for standard ANSI C libraries. On Mac OS X, it
 * can be compiled and run by executing the following commands in a terminal
 * window:
 *     gcc -o seconds seconds.c
 *     ./seconds
 */

// Compile note added by RKW
//    gcc -o hmac-sha256 hmac-sha256.c
// should work on latter-day gcc installs, but c99 can be made explicit this way:
//    gcc -std=c99 -o hmac-sha256 hmac-sha256.c

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
/* #include <string.h> */
#include <stdint.h>	//  Added by RKW, needed for types uint8_t, uint32_t; requires C99 compiler

/******************************************************************************
 * SHA-256.
 */

typedef struct {
    uint8_t		hash[32];	// Changed by RKW, unsigned char becomes uint8_t
    uint32_t	buffer[16];	// Changed by RKW, unsigned long becomes uint32_t
    uint32_t	state[8];	// Changed by RKW, unsinged long becomes uint32_t
    uint8_t		length[8];	// Changed by RKW, unsigned char becomes uint8_t
} sha256;

void sha256_initialize(sha256 *sha);

//  Changed by RKW, formal args are now const uint8_t, uint_32
//    from const unsigned char, unsigned long respectively
void sha256_update(sha256 *sha,
                   const uint8_t *message,
                   uint32_t length);

//  Changed by RKW, formal args are now const uint8_t, uint_32
//    from const unsigned char, unsigned long respectively
void sha256_finalize(sha256 *sha,
                     const uint8_t *message,
                     uint32_t length);

//  Changed by RKW, formal args are now uint8_t, const uint_8
//    from unsigned char, const unsigned char respectively
void sha256_get(uint8_t hash[32],
                const uint8_t *message,
                int length);

/******************************************************************************
 * HMAC-SHA256.
 */

typedef struct _hmac_sha256 {
    uint8_t	digest[32];	// Changed by RKW, unsigned char becomes uint_8
    uint8_t	key[64];	// Changed by RKW, unsigned char becomes uint_8
    sha256	sha;
} hmac_sha256;

//  Changed by RKW, formal arg is now const uint8_t
//    from const unsigned char
void hmac_sha256_initialize(hmac_sha256 *hmac,
                            const uint8_t *key, int length);

//  Changed by RKW, formal arg is now const uint8_t
//    from const unsigned char
void hmac_sha256_update(hmac_sha256 *hmac,
                        const uint8_t *message, int length);

//  Changed by RKW, formal arg is now const uint8_t
//    from const unsigned char
void hmac_sha256_finalize(hmac_sha256 *hmac,
                          const uint8_t *message, int length);

//  Changed by RKW, formal args are now uint8_t, const uint8_t
//    from unsinged char, const unsigned char respectively
void hmac_sha256_get(uint8_t digest[32],
                     const uint8_t *message, int message_length,
                     const uint8_t *key, int key_length);