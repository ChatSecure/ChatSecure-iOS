/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2012  Ian Goldberg, Chris Alexander, Willy Lew,
 *  			     Lisa Du, Nikita Borisov
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

#ifndef __PRIVKEY_H__
#define __PRIVKEY_H__

#include <stdio.h>
#include "privkey-t.h"
#include "userstate.h"

/* The length of a string representing a human-readable version of a
 * fingerprint (including the trailing NUL) */
#define OTRL_PRIVKEY_FPRINT_HUMAN_LEN 45

/* Convert a 20-byte hash value to a 45-byte human-readable value */
void otrl_privkey_hash_to_human(
	char human[OTRL_PRIVKEY_FPRINT_HUMAN_LEN],
	const unsigned char hash[20]);

/* Calculate a human-readable hash of our DSA public key.  Return it in
 * the passed fingerprint buffer.  Return NULL on error, or a pointer to
 * the given buffer on success. */
char *otrl_privkey_fingerprint(OtrlUserState us,
	char fingerprint[OTRL_PRIVKEY_FPRINT_HUMAN_LEN],
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

/* Free the memory associated with the pending privkey list */
void otrl_privkey_pending_forget_all(OtrlUserState us);

/* Begin a private key generation that will potentially take place in
 * a background thread.  This routine must be called from the main
 * thread.  It will set *newkeyp, which you can pass to
 * otrl_privkey_generate_calculate in a background thread.  If it
 * returns gcry_error(GPG_ERR_EEXIST), then a privkey creation for
 * this accountname/protocol is already in progress, and *newkeyp will
 * be set to NULL. */
gcry_error_t otrl_privkey_generate_start(OtrlUserState us,
	const char *accountname, const char *protocol, void **newkeyp);

/* Do the private key generation calculation.  You may call this from a
 * background thread.  When it completes, call
 * otrl_privkey_generate_finish from the _main_ thread. */
gcry_error_t otrl_privkey_generate_calculate(void *newkey);

/* Call this from the main thread only.  It will write the newly created
 * private key into the given file and store it in the OtrlUserState. */
gcry_error_t otrl_privkey_generate_finish(OtrlUserState us,
	void *newkey, const char *filename);

/* Call this from the main thread only.  It will write the newly created
 * private key into the given FILE* (which must be open for reading and
 * writing) and store it in the OtrlUserState. */
gcry_error_t otrl_privkey_generate_finish_FILEp(OtrlUserState us,
	void *newkey, FILE *privf);

/* Call this from the main thread only, in the event that the background
 * thread generating the key is cancelled.  The newkey is deallocated,
 * and must not be used further. */
void otrl_privkey_generate_cancelled(OtrlUserState us, void *newkey);

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
