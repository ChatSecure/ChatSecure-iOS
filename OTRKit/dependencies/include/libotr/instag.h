/*
 *  Off-the-Record Messaging library
 *  Copyright (C) 2004-2012  Ian Goldberg, Rob Smits, Chris Alexander,
 *  			      Willy Lew, Lisa Du, Nikita Borisov
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

#ifndef __INSTAG_H__
#define __INSTAG_H__

#include <stdio.h>
#include <errno.h>

#define OTRL_INSTAG_MASTER 0
#define OTRL_INSTAG_BEST 1 /* Most secure, based on: conv status,
			    * then fingerprint status, then most recent. */
#define OTRL_INSTAG_RECENT 2
#define OTRL_INSTAG_RECENT_RECEIVED 3
#define OTRL_INSTAG_RECENT_SENT 4

#define OTRL_MIN_VALID_INSTAG 0x100 /* Instag values below this are reserved
				     * for meta instags, defined above, */

typedef unsigned int otrl_instag_t;

/* The list of instance tags used for our accounts */
typedef struct s_OtrlInsTag {
    struct s_OtrlInsTag *next;
    struct s_OtrlInsTag **tous;

    char *accountname;
    char *protocol;
    otrl_instag_t instag;
} OtrlInsTag;

#include "userstate.h"

/* Forget the given instag. */
void otrl_instag_forget(OtrlInsTag* instag);

/* Forget all instags in a given OtrlUserState. */
void otrl_instag_forget_all(OtrlUserState us);

/* Fetch the instance tag from the given OtrlUserState associated with
 * the given account */
OtrlInsTag * otrl_instag_find(OtrlUserState us, const char *accountname,
	const char *protocol);

/* Read our instance tag from a file on disk into the given
 * OtrlUserState. */
gcry_error_t otrl_instag_read(OtrlUserState us, const char *filename);

/* Read our instance tag from a file on disk into the given
 * OtrlUserState. The FILE* must be open for reading. */
gcry_error_t otrl_instag_read_FILEp(OtrlUserState us, FILE *instf);

/* Return a new valid instance tag */
otrl_instag_t otrl_instag_get_new();

/* Get a new instance tag for the given account and write to file*/
gcry_error_t otrl_instag_generate(OtrlUserState us, const char *filename,
	const char *accountname, const char *protocol);

/* Get a new instance tag for the given account and write to file
 * The FILE* must be open for writing. */
gcry_error_t otrl_instag_generate_FILEp(OtrlUserState us, FILE *instf,
	const char *accountname, const char *protocol);

/* Write our instance tags to a file on disk. */
gcry_error_t otrl_instag_write(OtrlUserState us, const char *filename);

/* Write our instance tags to a file on disk.
 * The FILE* must be open for writing. */
gcry_error_t otrl_instag_write_FILEp(OtrlUserState us, FILE *instf);

#endif
