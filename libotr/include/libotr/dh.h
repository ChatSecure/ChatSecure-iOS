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

#ifndef __DH_H__
#define __DH_H__

#define DH1536_GROUP_ID 5

typedef struct {
    unsigned int groupid;
    gcry_mpi_t priv, pub;
} DH_keypair;

/* Which half of the secure session id should be shown in bold? */
typedef enum {
    OTRL_SESSIONID_FIRST_HALF_BOLD,
    OTRL_SESSIONID_SECOND_HALF_BOLD
} OtrlSessionIdHalf;

typedef struct {
    unsigned char sendctr[16];
    unsigned char rcvctr[16];
    gcry_cipher_hd_t sendenc;
    gcry_cipher_hd_t rcvenc;
    gcry_md_hd_t sendmac;
    unsigned char sendmackey[20];
    int sendmacused;
    gcry_md_hd_t rcvmac;
    unsigned char rcvmackey[20];
    int rcvmacused;
} DH_sesskeys;

/*
 * Call this once, at plugin load time.  It sets up the modulus and
 * generator MPIs.
 */
void otrl_dh_init(void);

/*
 * Initialize the fields of a DH keypair.
 */
void otrl_dh_keypair_init(DH_keypair *kp);

/*
 * Copy a DH_keypair.
 */
void otrl_dh_keypair_copy(DH_keypair *dst, const DH_keypair *src);

/*
 * Deallocate the contents of a DH_keypair (but not the DH_keypair
 * itself)
 */
void otrl_dh_keypair_free(DH_keypair *kp);

/*
 * Generate a DH keypair for a specified group.
 */ 
gcry_error_t otrl_dh_gen_keypair(unsigned int groupid, DH_keypair *kp);

/*
 * Construct session keys from a DH keypair and someone else's public
 * key.
 */
gcry_error_t otrl_dh_session(DH_sesskeys *sess, const DH_keypair *kp,
	gcry_mpi_t y);

/*
 * Compute the secure session id, two encryption keys, and four MAC keys
 * given our DH key and their DH public key.
 */
gcry_error_t otrl_dh_compute_v2_auth_keys(const DH_keypair *our_dh,
	gcry_mpi_t their_pub, unsigned char *sessionid, size_t *sessionidlenp,
	gcry_cipher_hd_t *enc_c, gcry_cipher_hd_t *enc_cp,
	gcry_md_hd_t *mac_m1, gcry_md_hd_t *mac_m1p,
	gcry_md_hd_t *mac_m2, gcry_md_hd_t *mac_m2p);

/*
 * Compute the secure session id, given our DH key and their DH public
 * key.
 */
gcry_error_t otrl_dh_compute_v1_session_id(const DH_keypair *our_dh,
	gcry_mpi_t their_pub, unsigned char *sessionid, size_t *sessionidlenp,
	OtrlSessionIdHalf *halfp);

/*
 * Deallocate the contents of a DH_sesskeys (but not the DH_sesskeys
 * itself)
 */
void otrl_dh_session_free(DH_sesskeys *sess);

/*
 * Blank out the contents of a DH_sesskeys (without releasing it)
 */
void otrl_dh_session_blank(DH_sesskeys *sess);

/* Increment the top half of a counter block */
void otrl_dh_incctr(unsigned char *ctr);

/* Compare two counter values (8 bytes each).  Return 0 if ctr1 == ctr2,
 * < 0 if ctr1 < ctr2 (as unsigned 64-bit values), > 0 if ctr1 > ctr2. */
int otrl_dh_cmpctr(const unsigned char *ctr1, const unsigned char *ctr2);

#endif
