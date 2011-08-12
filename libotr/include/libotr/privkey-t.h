/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2008  Ian Goldberg, Chris Alexander, Nikita Borisov
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
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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

#endif
