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

#ifndef __AUTH_H__
#define __AUTH_H__

#include <gcrypt.h>
#include "dh.h"

typedef enum {
    OTRL_AUTHSTATE_NONE,
    OTRL_AUTHSTATE_AWAITING_DHKEY,
    OTRL_AUTHSTATE_AWAITING_REVEALSIG,
    OTRL_AUTHSTATE_AWAITING_SIG,
    OTRL_AUTHSTATE_V1_SETUP
} OtrlAuthState;

typedef struct {
    OtrlAuthState authstate;              /* Our state */

    DH_keypair our_dh;                    /* Our D-H key */
    unsigned int our_keyid;               /* ...and its keyid */

    unsigned char *encgx;                 /* The encrypted value of g^x */
    size_t encgx_len;                     /*  ...and its length */
    unsigned char r[16];                  /* The encryption key */

    unsigned char hashgx[32];             /* SHA256(g^x) */

    gcry_mpi_t their_pub;                 /* Their D-H public key */
    unsigned int their_keyid;             /*  ...and its keyid */

    gcry_cipher_hd_t enc_c, enc_cp;       /* c and c' encryption keys */
    gcry_md_hd_t mac_m1, mac_m1p;         /* m1 and m1' MAC keys */
    gcry_md_hd_t mac_m2, mac_m2p;         /* m2 and m2' MAC keys */

    unsigned char their_fingerprint[20];  /* The fingerprint of their
					     long-term signing key */

    int initiated;                        /* Did we initiate this
					     authentication? */

    unsigned int protocol_version;        /* The protocol version number
					     used to authenticate. */

    unsigned char secure_session_id[20];  /* The secure session id */
    size_t secure_session_id_len;         /* And its actual length,
					     which may be either 20 (for
					     v1) or 8 (for v2) */
    OtrlSessionIdHalf session_id_half;    /* Which half of the session
					     id gets shown in bold */

    char *lastauthmsg;                    /* The last auth message
					     (base-64 encoded) we sent,
					     in case we need to
					     retransmit it. */
} OtrlAuthInfo;

#include "privkey-t.h"

/*
 * Initialize the fields of an OtrlAuthInfo (already allocated).
 */
void otrl_auth_new(OtrlAuthInfo *auth);

/*
 * Clear the fields of an OtrlAuthInfo (but leave it allocated).
 */
void otrl_auth_clear(OtrlAuthInfo *auth);

/*
 * Start a fresh AKE (version 2) using the given OtrlAuthInfo.  Generate
 * a fresh DH keypair to use.  If no error is returned, the message to
 * transmit will be contained in auth->lastauthmsg.
 */
gcry_error_t otrl_auth_start_v2(OtrlAuthInfo *auth);

/*
 * Handle an incoming D-H Commit Message.  If no error is returned, the
 * message to send will be left in auth->lastauthmsg.  Generate a fresh
 * keypair to use.
 */
gcry_error_t otrl_auth_handle_commit(OtrlAuthInfo *auth,
	const char *commitmsg);

/*
 * Handle an incoming D-H Key Message.  If no error is returned, and
 * *havemsgp is 1, the message to sent will be left in auth->lastauthmsg.
 * Use the given private authentication key to sign messages.
 */
gcry_error_t otrl_auth_handle_key(OtrlAuthInfo *auth, const char *keymsg,
	int *havemsgp, OtrlPrivKey *privkey);

/*
 * Handle an incoming Reveal Signature Message.  If no error is
 * returned, and *havemsgp is 1, the message to be sent will be left in
 * auth->lastauthmsg.  Use the given private authentication key to sign
 * messages.  Call the auth_succeeded callback if authentication is
 * successful.
 */
gcry_error_t otrl_auth_handle_revealsig(OtrlAuthInfo *auth,
	const char *revealmsg, int *havemsgp, OtrlPrivKey *privkey,
	gcry_error_t (*auth_succeeded)(const OtrlAuthInfo *auth, void *asdata),
	void *asdata);

/*
 * Handle an incoming Signature Message.  If no error is returned, and
 * *havemsgp is 1, the message to be sent will be left in
 * auth->lastauthmsg.  Call the auth_succeeded callback if
 * authentication is successful.
 */
gcry_error_t otrl_auth_handle_signature(OtrlAuthInfo *auth,
	const char *sigmsg, int *havemsgp,
	gcry_error_t (*auth_succeeded)(const OtrlAuthInfo *auth, void *asdata),
	void *asdata);

/*
 * Start a fresh AKE (version 1) using the given OtrlAuthInfo.  If
 * our_dh is NULL, generate a fresh DH keypair to use.  Otherwise, use a
 * copy of the one passed (with the given keyid).  Use the given private
 * key to sign the message.  If no error is returned, the message to
 * transmit will be contained in auth->lastauthmsg.
 */
gcry_error_t otrl_auth_start_v1(OtrlAuthInfo *auth, DH_keypair *our_dh,
	unsigned int our_keyid, OtrlPrivKey *privkey);

/*
 * Handle an incoming v1 Key Exchange Message.  If no error is returned,
 * and *havemsgp is 1, the message to be sent will be left in
 * auth->lastauthmsg.  Use the given private authentication key to sign
 * messages.  Call the auth_secceeded callback if authentication is
 * successful.  If non-NULL, use a copy of the given D-H keypair, with
 * the given keyid.
 */
gcry_error_t otrl_auth_handle_v1_key_exchange(OtrlAuthInfo *auth,
	const char *keyexchmsg, int *havemsgp, OtrlPrivKey *privkey,
	DH_keypair *our_dh, unsigned int our_keyid,
	gcry_error_t (*auth_succeeded)(const OtrlAuthInfo *auth, void *asdata),
	void *asdata);

#endif
