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

#ifndef __MESSAGE_H__
#define __MESSAGE_H__

typedef enum {
    OTRL_NOTIFY_ERROR,
    OTRL_NOTIFY_WARNING,
    OTRL_NOTIFY_INFO
} OtrlNotifyLevel;

typedef struct s_OtrlMessageAppOps {
    /* Return the OTR policy for the given context. */
    OtrlPolicy (*policy)(void *opdata, ConnContext *context);

    /* Create a private key for the given accountname/protocol if
     * desired. */
    void (*create_privkey)(void *opdata, const char *accountname,
	    const char *protocol);

    /* Report whether you think the given user is online.  Return 1 if
     * you think he is, 0 if you think he isn't, -1 if you're not sure.
     *
     * If you return 1, messages such as heartbeats or other
     * notifications may be sent to the user, which could result in "not
     * logged in" errors if you're wrong. */
    int (*is_logged_in)(void *opdata, const char *accountname,
	    const char *protocol, const char *recipient);

    /* Send the given IM to the given recipient from the given
     * accountname/protocol. */
    void (*inject_message)(void *opdata, const char *accountname,
	    const char *protocol, const char *recipient, const char *message);

    /* Display a notification message for a particular accountname /
     * protocol / username conversation. */
    void (*notify)(void *opdata, OtrlNotifyLevel level,
	    const char *accountname, const char *protocol,
	    const char *username, const char *title,
	    const char *primary, const char *secondary);

    /* Display an OTR control message for a particular accountname /
     * protocol / username conversation.  Return 0 if you are able to
     * successfully display it.  If you return non-0 (or if this
     * function is NULL), the control message will be displayed inline,
     * as a received message, or else by using the above notify()
     * callback. */
    int (*display_otr_message)(void *opdata, const char *accountname,
	    const char *protocol, const char *username, const char *msg);

    /* When the list of ConnContexts changes (including a change in
     * state), this is called so the UI can be updated. */
    void (*update_context_list)(void *opdata);

    /* Return a newly allocated string containing a human-friendly name
     * for the given protocol id */
    const char *(*protocol_name)(void *opdata, const char *protocol);

    /* Deallocate a string allocated by protocol_name */
    void (*protocol_name_free)(void *opdata, const char *protocol_name);

    /* A new fingerprint for the given user has been received. */
    void (*new_fingerprint)(void *opdata, OtrlUserState us,
	    const char *accountname, const char *protocol,
	    const char *username, unsigned char fingerprint[20]);

    /* The list of known fingerprints has changed.  Write them to disk. */
    void (*write_fingerprints)(void *opdata);

    /* A ConnContext has entered a secure state. */
    void (*gone_secure)(void *opdata, ConnContext *context);

    /* A ConnContext has left a secure state. */
    void (*gone_insecure)(void *opdata, ConnContext *context);

    /* We have completed an authentication, using the D-H keys we
     * already knew.  is_reply indicates whether we initiated the AKE. */
    void (*still_secure)(void *opdata, ConnContext *context, int is_reply);

    /* Log a message.  The passed message will end in "\n". */
    void (*log_message)(void *opdata, const char *message);

    /* Find the maximum message size supported by this protocol. */
    int (*max_message_size)(void *opdata, ConnContext *context);

    /* Return a newly allocated string containing a human-friendly
     * representation for the given account */
    const char *(*account_name)(void *opdata, const char *account,
	    const char *protocol);

    /* Deallocate a string returned by account_name */
    void (*account_name_free)(void *opdata, const char *account_name);

} OtrlMessageAppOps;

/* Deallocate a message allocated by other otrl_message_* routines. */
void otrl_message_free(char *message);

/* Handle a message about to be sent to the network.  It is safe to pass
 * all messages about to be sent to this routine.  add_appdata is a
 * function that will be called in the event that a new ConnContext is
 * created.  It will be passed the data that you supplied, as well as a
 * pointer to the new ConnContext.  You can use this to add
 * application-specific information to the ConnContext using the
 * "context->app" field, for example.  If you don't need to do this, you
 * can pass NULL for the last two arguments of otrl_message_sending.  
 *
 * tlvs is a chain of OtrlTLVs to append to the private message.  It is
 * usually correct to just pass NULL here.
 *
 * If this routine returns non-zero, then the library tried to encrypt
 * the message, but for some reason failed.  DO NOT send the message in
 * the clear in that case.
 * 
 * If *messagep gets set by the call to something non-NULL, then you
 * should replace your message with the contents of *messagep, and
 * send that instead.  Call otrl_message_free(*messagep) when you're
 * done with it. */
gcry_error_t otrl_message_sending(OtrlUserState us,
	const OtrlMessageAppOps *ops,
	void *opdata, const char *accountname, const char *protocol,
	const char *recipient, const char *message, OtrlTLV *tlvs,
	char **messagep,
	void (*add_appdata)(void *data, ConnContext *context),
	void *data);

/* Handle a message just received from the network.  It is safe to pass
 * all received messages to this routine.  add_appdata is a function
 * that will be called in the event that a new ConnContext is created.
 * It will be passed the data that you supplied, as well as
 * a pointer to the new ConnContext.  You can use this to add
 * application-specific information to the ConnContext using the
 * "context->app" field, for example.  If you don't need to do this, you
 * can pass NULL for the last two arguments of otrl_message_receiving.  
 *
 * If otrl_message_receiving returns 1, then the message you received
 * was an internal protocol message, and no message should be delivered
 * to the user.
 *
 * If it returns 0, then check if *messagep was set to non-NULL.  If
 * so, replace the received message with the contents of *messagep, and
 * deliver that to the user instead.  You must call
 * otrl_message_free(*messagep) when you're done with it.  If tlvsp is
 * non-NULL, *tlvsp will be set to a chain of any TLVs that were
 * transmitted along with this message.  You must call
 * otrl_tlv_free(*tlvsp) when you're done with those.
 *
 * If otrl_message_receiving returns 0 and *messagep is NULL, then this
 * was an ordinary, non-OTR message, which should just be delivered to
 * the user without modification. */
int otrl_message_receiving(OtrlUserState us, const OtrlMessageAppOps *ops,
	void *opdata, const char *accountname, const char *protocol,
	const char *sender, const char *message, char **newmessagep,
	OtrlTLV **tlvsp,
	void (*add_appdata)(void *data, ConnContext *context),
	void *data);

/* Send a message to the network, fragmenting first if necessary.
 * All messages to be sent to the network should go through this
 * method immediately before they are sent, ie after encryption. */
gcry_error_t otrl_message_fragment_and_send(const OtrlMessageAppOps *ops,
	void *opdata, ConnContext *context, const char *message,
	OtrlFragmentPolicy fragPolicy, char **returnFragment);

/* Put a connection into the PLAINTEXT state, first sending the
 * other side a notice that we're doing so if we're currently ENCRYPTED,
 * and we think he's logged in. */
void otrl_message_disconnect(OtrlUserState us, const OtrlMessageAppOps *ops,
	void *opdata, const char *accountname, const char *protocol,
	const char *username);

/* Initiate the Socialist Millionaires' Protocol */
void otrl_message_initiate_smp(OtrlUserState us, const OtrlMessageAppOps *ops,
	void *opdata, ConnContext *context, const unsigned char *secret,
	size_t secretlen);

/* Initiate the Socialist Millionaires' Protocol and send a prompt
 * question to the buddy */
void otrl_message_initiate_smp_q(OtrlUserState us,
	const OtrlMessageAppOps *ops, void *opdata, ConnContext *context,
	const char *question, const unsigned char *secret, size_t secretlen);

/* Respond to a buddy initiating the Socialist Millionaires' Protocol */
void otrl_message_respond_smp(OtrlUserState us, const OtrlMessageAppOps *ops,
	void *opdata, ConnContext *context, const unsigned char *secret,
	size_t secretlen);

/* Abort the SMP.  Called when an unexpected SMP message breaks the
 * normal flow. */
void otrl_message_abort_smp(OtrlUserState us, const OtrlMessageAppOps *ops,
	void *opdata, ConnContext *context);

#endif
