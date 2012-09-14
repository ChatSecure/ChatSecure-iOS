/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2009  Ian Goldberg, Chris Alexander, Willy Lew,
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

#ifndef __PRIVKEY_T_H__
#define __PRIVKEY_T_H__

#include <gcrypt.h>

typedef struct s_OtrlPrivKey {
    struct s_OtrlPrivKey *next;
    struct s_OtrlPrivKey **tous;

    char *accountname;
    char *protocol;
    unsigned short pubkey_type;
    gcry_sexp_t privkey;
    unsigned char *pubkey_data;
    size_t pubkey_datalen;
} OtrlPrivKey;

#define OTRL_PUBKEY_TYPE_DSA 0x0000

/* The list of privkeys currently being constructed, possibly in a
 * background thread */
typedef struct s_OtrlPendingPrivKey {
    struct s_OtrlPendingPrivKey *next;
    struct s_OtrlPendingPrivKey **tous;

    char *accountname;
    char *protocol;
} OtrlPendingPrivKey;

#endif
