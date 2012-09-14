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

#ifndef __TLV_H__
#define __TLV_H__

typedef struct s_OtrlTLV {
    unsigned short type;
    unsigned short len;
    unsigned char *data;
    struct s_OtrlTLV *next;
} OtrlTLV;

/* TLV types */

/* This is just padding for the encrypted message, and should be ignored. */
#define OTRL_TLV_PADDING         0x0000

/* The sender has thrown away his OTR session keys with you */
#define OTRL_TLV_DISCONNECTED    0x0001

/* The message contains a step in the Socialist Millionaires' Protocol. */
#define OTRL_TLV_SMP1            0x0002
#define OTRL_TLV_SMP2            0x0003
#define OTRL_TLV_SMP3            0x0004
#define OTRL_TLV_SMP4            0x0005
#define OTRL_TLV_SMP_ABORT       0x0006
/* Like OTRL_TLV_SMP1, but there's a question for the buddy at the
 * beginning */
#define OTRL_TLV_SMP1Q           0x0007
/* Tell the application the current "extra" symmetric key */
/* XXX: Document this in the protocol spec:
 * The body of the TLV will begin with a 4-byte indication of what this
 * symmetric key will be used for (file transfer, voice encryption,
 * etc.).  After that, the contents are use-specific (which file, etc.).
 * There are no currently defined uses. */
#define OTRL_TLV_SYMKEY          0x0008

/* Make a single TLV, copying the supplied data */
OtrlTLV *otrl_tlv_new(unsigned short type, unsigned short len,
	const unsigned char *data);

/* Construct a chain of TLVs from the given data */
OtrlTLV *otrl_tlv_parse(const unsigned char *serialized, size_t seriallen);

/* Deallocate a chain of TLVs */
void otrl_tlv_free(OtrlTLV *tlv);

/* Find the serialized length of a chain of TLVs */
size_t otrl_tlv_seriallen(const OtrlTLV *tlv);

/* Serialize a chain of TLVs.  The supplied buffer must already be large
 * enough. */
void otrl_tlv_serialize(unsigned char *buf, const OtrlTLV *tlv);

/* Return the first TLV with the given type in the chain, or NULL if one
 * isn't found.  (The tlvs argument isn't const because the return type
 * needs to be non-const.) */
OtrlTLV *otrl_tlv_find(OtrlTLV *tlvs, unsigned short type);

#endif
