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

#ifndef __SM_H__
#define __SM_H__

#include <gcrypt.h>

#define SM_HASH_ALGORITHM GCRY_MD_SHA256
#define SM_DIGEST_SIZE 32

typedef enum {
    OTRL_SMP_EXPECT1,
    OTRL_SMP_EXPECT2,
    OTRL_SMP_EXPECT3,
    OTRL_SMP_EXPECT4,
    OTRL_SMP_EXPECT5
} NextExpectedSMP;

typedef enum {
    OTRL_SMP_PROG_OK = 0,            /* All is going fine so far */
    OTRL_SMP_PROG_CHEATED = -2,      /* Some verification failed */
    OTRL_SMP_PROG_FAILED = -1,       /* The secrets didn't match */
    OTRL_SMP_PROG_SUCCEEDED = 1      /* The SMP completed successfully */
} OtrlSMProgState;

typedef struct {
    gcry_mpi_t secret, x2, x3, g1, g2, g3, g3o, p, q, pab, qab;
    NextExpectedSMP nextExpected;
    int received_question;  /* 1 if we received a question in an SMP1Q TLV */
    OtrlSMProgState sm_prog_state;
} OtrlSMState;

typedef OtrlSMState OtrlSMAliceState;
typedef OtrlSMState OtrlSMBobState;

/*
 * Call this once, at plugin load time.  It sets up the modulus and
 * generator MPIs.
 */
void otrl_sm_init(void);

/*
 * Initialize the fields of a SM state.
 */
void otrl_sm_state_new(OtrlSMState *smst);

/*
 * Initialize the fields of a SM state.  Called the first time that
 * a user begins an SMP session.
 */
void otrl_sm_state_init(OtrlSMState *smst);

/*
 * Deallocate the contents of a OtrlSMState (but not the OtrlSMState
 * itself)
 */
void otrl_sm_state_free(OtrlSMState *smst);

gcry_error_t otrl_sm_step1(OtrlSMAliceState *astate, const unsigned char* secret, int secretlen, unsigned char** output, int* outputlen);
gcry_error_t otrl_sm_step2a(OtrlSMBobState *bstate, const unsigned char* input, const int inputlen, int received_question);
gcry_error_t otrl_sm_step2b(OtrlSMBobState *bstate, const unsigned char* secret, int secretlen, unsigned char **output, int* outputlen);
gcry_error_t otrl_sm_step3(OtrlSMAliceState *astate, const unsigned char* input, const int inputlen, unsigned char **output, int* outputlen);
gcry_error_t otrl_sm_step4(OtrlSMBobState *bstate, const unsigned char* input, const int inputlen, unsigned char **output, int* outputlen);
gcry_error_t otrl_sm_step5(OtrlSMAliceState *astate, const unsigned char* input, const int inputlen);

#endif
