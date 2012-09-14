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

#ifndef __PROTO_H__
#define __PROTO_H__

#include "context.h"
#include "version.h"
#include "tlv.h"

/* If we ever see this sequence in a plaintext message, we'll assume the
 * other side speaks OTR, and try to establish a connection. */
#define OTRL_MESSAGE_TAG_BASE " \t  \t\t\t\t \t \t \t  "
/* The following must each be of length 8 */
#define OTRL_MESSAGE_TAG_V1 " \t \t  \t "
#define OTRL_MESSAGE_TAG_V2 "  \t\t  \t "
#define OTRL_MESSAGE_TAG_V3 "  \t\t  \t\t"

/* The possible flags contained in a Data Message */
#define OTRL_MSGFLAGS_IGNORE_UNREADABLE		0x01

typedef unsigned int OtrlPolicy;

#define OTRL_POLICY_ALLOW_V1			0x01
#define OTRL_POLICY_ALLOW_V2			0x02
#define OTRL_POLICY_ALLOW_V3			0x04
#define OTRL_POLICY_REQUIRE_ENCRYPTION		0x08
#define OTRL_POLICY_SEND_WHITESPACE_TAG		0x10
#define OTRL_POLICY_WHITESPACE_START_AKE	0x20
#define OTRL_POLICY_ERROR_START_AKE		0x40

#define OTRL_POLICY_VERSION_MASK (OTRL_POLICY_ALLOW_V1 | OTRL_POLICY_ALLOW_V2 |\
	OTRL_POLICY_ALLOW_V3)

/* Length of OTR message headers */
#define OTRL_HEADER_LEN		3
#define OTRL_B64_HEADER_LEN	4

/* Analogous to v1 policies */
#define OTRL_POLICY_NEVER			0x00
#define OTRL_POLICY_OPPORTUNISTIC \
	    ( OTRL_POLICY_ALLOW_V2 | \
	    OTRL_POLICY_ALLOW_V3 | \
	    OTRL_POLICY_SEND_WHITESPACE_TAG | \
	    OTRL_POLICY_WHITESPACE_START_AKE | \
	    OTRL_POLICY_ERROR_START_AKE )
#define OTRL_POLICY_MANUAL \
	    ( OTRL_POLICY_ALLOW_V2 | \
	    OTRL_POLICY_ALLOW_V3)
#define OTRL_POLICY_ALWAYS \
	    ( OTRL_POLICY_ALLOW_V2 | \
	    OTRL_POLICY_ALLOW_V3 | \
	    OTRL_POLICY_REQUIRE_ENCRYPTION | \
	    OTRL_POLICY_WHITESPACE_START_AKE | \
	    OTRL_POLICY_ERROR_START_AKE )
#define OTRL_POLICY_DEFAULT OTRL_POLICY_OPPORTUNISTIC

typedef enum {
    OTRL_MSGTYPE_NOTOTR,
    OTRL_MSGTYPE_TAGGEDPLAINTEXT,
    OTRL_MSGTYPE_QUERY,
    OTRL_MSGTYPE_DH_COMMIT,
    OTRL_MSGTYPE_DH_KEY,
    OTRL_MSGTYPE_REVEALSIG,
    OTRL_MSGTYPE_SIGNATURE,
    OTRL_MSGTYPE_V1_KEYEXCH,
    OTRL_MSGTYPE_DATA,
    OTRL_MSGTYPE_ERROR,
    OTRL_MSGTYPE_UNKNOWN
} OtrlMessageType;

typedef enum {
    OTRL_FRAGMENT_UNFRAGMENTED,
    OTRL_FRAGMENT_INCOMPLETE,
    OTRL_FRAGMENT_COMPLETE
} OtrlFragmentResult;

typedef enum {
    OTRL_FRAGMENT_SEND_SKIP, /* Return new message back to caller,
			      * but don't inject. */
    OTRL_FRAGMENT_SEND_ALL,
    OTRL_FRAGMENT_SEND_ALL_BUT_FIRST,
    OTRL_FRAGMENT_SEND_ALL_BUT_LAST
} OtrlFragmentPolicy;

/* Initialize the OTR library.  Pass the version of the API you are
 * using. */
gcry_error_t otrl_init(unsigned int ver_major, unsigned int ver_minor,
	unsigned int ver_sub);

/* Shortcut */
#define OTRL_INIT do { \
	if (otrl_init(OTRL_VERSION_MAJOR, OTRL_VERSION_MINOR, \
		OTRL_VERSION_SUB)) { \
	    exit(1); \
	} \
    } while(0)

/* Return a pointer to a static string containing the version number of
 * the OTR library. */
const char *otrl_version(void);

/* Return a pointer to a newly-allocated OTR query message, customized
 * with our name.  The caller should free() the result when he's done
 * with it. */
char *otrl_proto_default_query_msg(const char *ourname, OtrlPolicy policy);

/* Return the best version of OTR support by both sides, given an OTR
 * Query Message and the local policy. */
unsigned int otrl_proto_query_bestversion(const char *querymsg,
	OtrlPolicy policy);

/* Locate any whitespace tag in this message, and return the best
 * version of OTR support on both sides.  Set *starttagp and *endtagp to
 * the start and end of the located tag, so that it can be snipped out. */
unsigned int otrl_proto_whitespace_bestversion(const char *msg,
	const char **starttagp, const char **endtagp, OtrlPolicy policy);

/* Find the message type. */
OtrlMessageType otrl_proto_message_type(const char *message);

/* Find the message version. */
int otrl_proto_message_version(const char *message);

/* Find the instance tags in this message. */
gcry_error_t otrl_proto_instance(const char *otrmsg,
	unsigned int *instance_from, unsigned int *instance_to);

/* Create an OTR Data message.  Pass the plaintext as msg, and an
 * optional chain of TLVs.  A newly-allocated string will be returned in
 * *encmessagep. Put the current extra symmetric key into extrakey
 * (if non-NULL). */
gcry_error_t otrl_proto_create_data(char **encmessagep, ConnContext *context,
	const char *msg, const OtrlTLV *tlvs, unsigned char flags,
	unsigned char *extrakey);

/* Extract the flags from an otherwise unreadable Data Message. */
gcry_error_t otrl_proto_data_read_flags(const char *datamsg,
	unsigned char *flagsp);

/* Accept an OTR Data Message in datamsg.  Decrypt it and put the
 * plaintext into *plaintextp, and any TLVs into tlvsp.  Put any
 * received flags into *flagsp (if non-NULL).  Put the current extra
 * symmetric key into extrakey (if non-NULL). */
gcry_error_t otrl_proto_accept_data(char **plaintextp, OtrlTLV **tlvsp,
	ConnContext *context, const char *datamsg, unsigned char *flagsp,
	unsigned char *extrakey);

/* Accumulate a potential fragment into the current context. */
OtrlFragmentResult otrl_proto_fragment_accumulate(char **unfragmessagep,
	ConnContext *context, const char *msg);

gcry_error_t otrl_proto_fragment_create(int mms, int fragment_count,
	char ***fragments, ConnContext *context, const char *message);

void otrl_proto_fragment_free(char ***fragments, unsigned short arraylen);
#endif
