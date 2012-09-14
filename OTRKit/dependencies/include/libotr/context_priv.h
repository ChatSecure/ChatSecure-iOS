/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2012  Ian Goldberg, Chris Alexander, Willy Lew,
 *			     Lisa Du, Nikita Borisov
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

#ifndef __CONTEXT_PRIV_H__
#define __CONTEXT_PRIV_H__

#include <gcrypt.h>

#include "dh.h"
#include "auth.h"
#include "sm.h"

typedef struct context_priv {
	/* The part of the fragmented message we've seen so far */
	char *fragment;

	/* The length of fragment */
	size_t fragment_len;

	/* The total number of fragments in this message */
	unsigned short fragment_n;

	/* The highest fragment number we've seen so far for this message */
	unsigned short fragment_k;

	/* current keyid used by other side; this is set to 0 if we get
	 * a OTRL_TLV_DISCONNECTED message from them. */
	unsigned int their_keyid;

	/* Y[their_keyid] (their DH pubkey) */
	gcry_mpi_t their_y;

	/* Y[their_keyid-1] (their prev DH pubkey) */
	gcry_mpi_t their_old_y;

	/* current keyid used by us */
	unsigned int our_keyid;

	/* DH key[our_keyid] */
	DH_keypair our_dh_key;

	/* DH key[our_keyid-1] */
	DH_keypair our_old_dh_key;

	/* sesskeys[i][j] are the session keys derived from DH
	 * key[our_keyid-i] and mpi Y[their_keyid-j] */
	DH_sesskeys sesskeys[2][2];

	/* saved mac keys to be revealed later */
	unsigned int numsavedkeys;
	unsigned char *saved_mac_keys;

	/* generation number: increment every time we go private, and never
	 * reset to 0 (unless we remove the context entirely) */
	unsigned int generation;

	/* The last time a Data Message was sent */
	time_t lastsent;

	/* The last time a Data Message was received */
	time_t lastrecv;

	/* The plaintext of the last Data Message sent */
	char *lastmessage;

	/* Is the last message eligible for retransmission? */
	int may_retransmit;

} ConnContextPriv;

/* Create a new private connection context. */
ConnContextPriv *otrl_context_priv_new();

/* Frees up memory that was used in otrl_context_priv_new */
void otrl_context_priv_force_finished(ConnContextPriv *context_priv);

#endif
