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

#ifndef __PRIVKEY_H__
#define __PRIVKEY_H__

#include <stdio.h>
#include "privkey-t.h"
#include "userstate.h"

/* Convert a 20-byte hash value to a 45-byte human-readable value */
void otrl_privkey_hash_to_human(char human[45], const unsigned char hash[20]);

/* Calculate a human-readable hash of our DSA public key.  Return it in
 * the passed fingerprint buffer.  Return NULL on error, or a pointer to
 * the given buffer on success. */
char *otrl_privkey_fingerprint(OtrlUserState us, char fingerprint[45],
	const char *accountname, const char *protocol);

/* Calculate a raw hash of our DSA public key.  Return it in the passed
 * fingerprint buffer.  Return NULL on error, or a pointer to the given
 * buffer on success. */
unsigned char *otrl_privkey_fingerprint_raw(OtrlUserState us,
	unsigned char hash[20], const char *accountname, const char *protocol);

/* Read a sets of private DSA keys from a file on disk into the given
 * OtrlUserState. */
gcry_error_t otrl_privkey_read(OtrlUserState us, const char *filename);

/* Read a sets of private DSA keys from a FILE* into the given
 * OtrlUserState.  The FILE* must be open for reading. */
gcry_error_t otrl_privkey_read_FILEp(OtrlUserState us, FILE *privf);

/* Generate a private DSA key for a given account, storing it into a
 * file on disk, and loading it into the given OtrlUserState.  Overwrite any
 * previously generated keys for that account in that OtrlUserState. */
gcry_error_t otrl_privkey_generate(OtrlUserState us, const char *filename,
	const char *accountname, const char *protocol);

/* Generate a private DSA key for a given account, storing it into a
 * FILE*, and loading it into the given OtrlUserState.  Overwrite any
 * previously generated keys for that account in that OtrlUserState.
 * The FILE* must be open for reading and writing. */
gcry_error_t otrl_privkey_generate_FILEp(OtrlUserState us, FILE *privf,
	const char *accountname, const char *protocol);

/* Read the fingerprint store from a file on disk into the given
 * OtrlUserState.  Use add_app_data to add application data to each
 * ConnContext so created. */
gcry_error_t otrl_privkey_read_fingerprints(OtrlUserState us,
	const char *filename,
	void (*add_app_data)(void *data, ConnContext *context),
	void  *data);

/* Read the fingerprint store from a FILE* into the given
 * OtrlUserState.  Use add_app_data to add application data to each
 * ConnContext so created.  The FILE* must be open for reading. */
gcry_error_t otrl_privkey_read_fingerprints_FILEp(OtrlUserState us,
	FILE *storef,
	void (*add_app_data)(void *data, ConnContext *context),
	void  *data);

/* Write the fingerprint store from a given OtrlUserState to a file on disk. */
gcry_error_t otrl_privkey_write_fingerprints(OtrlUserState us,
	const char *filename);

/* Write the fingerprint store from a given OtrlUserState to a FILE*.
 * The FILE* must be open for writing. */
gcry_error_t otrl_privkey_write_fingerprints_FILEp(OtrlUserState us,
	FILE *storef);

/* Fetch the private key from the given OtrlUserState associated with
 * the given account */
OtrlPrivKey *otrl_privkey_find(OtrlUserState us, const char *accountname,
	const char *protocol);

/* Forget a private key */
void otrl_privkey_forget(OtrlPrivKey *privkey);

/* Forget all private keys in a given OtrlUserState. */
void otrl_privkey_forget_all(OtrlUserState us);

/* Sign data using a private key.  The data must be small enough to be
 * signed (i.e. already hashed, if necessary).  The signature will be
 * returned in *sigp, which the caller must free().  Its length will be
 * returned in *siglenp. */
gcry_error_t otrl_privkey_sign(unsigned char **sigp, size_t *siglenp,
	OtrlPrivKey *privkey, const unsigned char *data, size_t len);

/* Verify a signature on data using a public key.  The data must be
 * small enough to be signed (i.e. already hashed, if necessary). */
gcry_error_t otrl_privkey_verify(const unsigned char *sigbuf, size_t siglen,
	unsigned short pubkey_type, gcry_sexp_t pubs,
	const unsigned char *data, size_t len);

#endif
