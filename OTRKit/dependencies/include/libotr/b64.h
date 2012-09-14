/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2012  Ian Goldberg, Chris Alexander, Willy Lew,
 *  			     Nikita Borisov
 *                           <otr@cypherpunks.ca>
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of version 2.1 of the GNU Lesser General
 *  Public License as published by the Free Software Foundation.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef __B64_H__
#define __B64_H__

#include <stdlib.h>

/* Base64 encodes blocks of this many bytes: */
#define OTRL_B64_DECODED_LEN 3
/* into blocks of this many bytes: */
#define OTRL_B64_ENCODED_LEN 4

/* An encoded block of length encoded_len can turn into a maximum of
 * this many decoded bytes: */
#define OTRL_B64_MAX_DECODED_SIZE(encoded_len) \
    (((encoded_len + OTRL_B64_ENCODED_LEN - 1) / OTRL_B64_ENCODED_LEN) \
	* OTRL_B64_DECODED_LEN)

/*
 * base64 encode data.  Insert no linebreaks or whitespace.
 *
 * The buffer base64data must contain at least ((datalen+2)/3)*4 bytes of
 * space.  This function will return the number of bytes actually used.
 */
size_t otrl_base64_encode(char *base64data, const unsigned char *data,
	size_t datalen);

/*
 * base64 decode data.  Skip non-base64 chars, and terminate at the
 * first '=', or the end of the buffer.
 *
 * The buffer data must contain at least ((base64len+3) / 4) * 3 bytes
 * of space.  This function will return the number of bytes actually
 * used.
 */
size_t otrl_base64_decode(unsigned char *data, const char *base64data,
	size_t base64len);

/*
 * Base64-encode a block of data, stick "?OTR:" and "." around it, and
 * return the result, or NULL in the event of a memory error.
 */
char *otrl_base64_otr_encode(const unsigned char *buf, size_t buflen);

/*
 * Base64-decode the portion of the given message between "?OTR:" and
 * ".".  Set *bufp to the decoded data, and set *lenp to its length.
 * The caller must free() the result.  Return 0 on success, -1 on a
 * memory error, or -2 on invalid input.
 */
int otrl_base64_otr_decode(const char *msg, unsigned char **bufp,
	size_t *lenp);

#endif
