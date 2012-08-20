/*
 * OTRKit.m
 * OTRKit
 *
 * Created by Chris Ballinger on 9/4/11.
 * Copyright (c) 2012 Chris Ballinger. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "OTRKit.h"
#import "proto.h"
#import "message.h"
#import "privkey.h"

#define PRIVKEYFNAME @"otr.private_key"
#define STOREFNAME @"otr.fingerprints"

static OtrlUserState userState;

@interface OTRKit(Private)
- (void) updateEncryptionStatusWithContext:(ConnContext*)context;
@end

@implementation OTRKit
@synthesize delegate;

static OtrlPolicy policy_cb(void *opdata, ConnContext *context)
{
    return OTRL_POLICY_DEFAULT;
}

static const char *protocol_name_cb(void *opdata, const char *protocol)
{
    return protocol;
}

static void protocol_name_free_cb(void *opdata, const char *protocol_name)
{}

static void create_privkey_cb(void *opdata, const char *accountname,
                              const char *protocol)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(createPrivateKeyForAccountName:protocol:)]) {
        [otrKit.delegate createPrivateKeyForAccountName:[NSString stringWithUTF8String:accountname] protocol:[NSString stringWithUTF8String:protocol]];
    } else {
        FILE *privf;
        NSString *path = [otrKit privateKeyPath];
        privf = fopen([path UTF8String], "w+b");
        otrl_privkey_generate_FILEp(userState, privf, accountname, protocol);
        fclose(privf);
    }
    
    
}

static int is_logged_in_cb(void *opdata, const char *accountname,
                           const char *protocol, const char *recipient)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(recipientIsLoggedIn:accountName:protocol:)]) {
        BOOL isLoggedIn = [otrKit.delegate recipientIsLoggedIn:[NSString stringWithUTF8String:recipient] accountName:[NSString stringWithUTF8String:accountname] protocol:[NSString stringWithUTF8String:protocol]];
        return isLoggedIn;
    }
    
    return -1;
}

static void inject_message_cb(void *opdata, const char *accountname,
                              const char *protocol, const char *recipient, const char *message)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(injectMessage:recipient:accountName:protocol:)]) {
        [otrKit.delegate injectMessage:[NSString stringWithUTF8String:message] recipient:[NSString stringWithUTF8String:recipient] accountName:[NSString stringWithUTF8String:accountname] protocol:[NSString stringWithUTF8String:protocol]];
    } else {
        NSLog(@"Your delegate must implement the injectMessage:recipient:accountName:protocol: selector!");
    }
}


static void notify_cb(void *opdata, OtrlNotifyLevel level,
                      const char *accountname, const char *protocol, const char *username,
                      const char *title, const char *primary, const char *secondary)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(showNotificationForAccountName:protocol:userName:title:primary:secondary:level:)]) {
        [otrKit.delegate showNotificationForAccountName:[NSString stringWithUTF8String:accountname] protocol:[NSString stringWithUTF8String:protocol] userName:[NSString stringWithUTF8String:username] title:[NSString stringWithUTF8String:title] primary:[NSString stringWithUTF8String:primary] secondary:[NSString stringWithUTF8String:secondary] level:level];
    }
}

static int display_otr_message_cb(void *opdata, const char *accountname,
                                  const char *protocol, const char *username, const char *msg)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(showMessageDialogForAccountName:protocol:userName:message:)]) {
        [otrKit.delegate showMessageDialogForAccountName:[NSString stringWithUTF8String:accountname] protocol:[NSString stringWithUTF8String:protocol] userName:[NSString stringWithUTF8String:username] message:[NSString stringWithUTF8String:msg]];
    }
    
    return 0;
}

static void update_context_list_cb(void *opdata)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(updateContextList)]) {
        [otrKit.delegate updateContextList];
    }
}

static void confirm_fingerprint_cb(void *opdata, OtrlUserState us,
                                   const char *accountname, const char *protocol, const char *username,
                                   unsigned char fingerprint[20])
{
    char our_hash[45], their_hash[45];
    
    ConnContext *context = otrl_context_find(userState, username,accountname, protocol,NO,NULL,NULL, NULL);
    
    otrl_privkey_fingerprint(userState, our_hash, context->accountname, context->protocol);
    
    otrl_privkey_hash_to_human(their_hash, fingerprint);
    
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(showFingerprintConfirmationForAccountName:protocol:userName:theirHash:ourHash:)]) {
        [otrKit.delegate showFingerprintConfirmationForAccountName:[NSString stringWithUTF8String:accountname] protocol:[NSString stringWithUTF8String:protocol] userName:[NSString stringWithUTF8String:username] theirHash:[NSString stringWithUTF8String:their_hash] ourHash:[NSString stringWithUTF8String:our_hash]];
    }
}

static void write_fingerprints_cb(void *opdata)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(writeFingerprints)]) {
        [otrKit.delegate writeFingerprints];
    } else {
        FILE *storef;
        NSString *path = [otrKit fingerprintsPath];
        storef = fopen([path UTF8String], "wb");
        if (!storef) return;
        otrl_privkey_write_fingerprints_FILEp(userState, storef);
        fclose(storef);
    }
}


static void gone_secure_cb(void *opdata, ConnContext *context)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    [otrKit updateEncryptionStatusWithContext:context];

}

static void gone_insecure_cb(void *opdata, ConnContext *context) // this method is never called
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    [otrKit updateEncryptionStatusWithContext:context];
}

- (void) updateEncryptionStatusWithContext:(ConnContext*)context {
    if (delegate && [delegate respondsToSelector:@selector(updateMessageStateForUsername:accountName:protocol:messageState:)]) {
        OTRKitMessageState messageState = [self messageStateForUsername:[NSString stringWithUTF8String:context->username] accountName:[NSString stringWithUTF8String:context->accountname] protocol:[NSString stringWithUTF8String:context->protocol]];
        [delegate updateMessageStateForUsername:[NSString stringWithUTF8String:context->username] accountName:[NSString stringWithUTF8String:context->accountname] protocol:[NSString stringWithUTF8String:context->protocol] messageState:messageState];
    } else {
        NSLog(@"Your delegate must implement the updateMessageStateForUsername:accountName:protocol:messageState: selector!");
    }
}

static void still_secure_cb(void *opdata, ConnContext *context, int is_reply)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    [otrKit updateEncryptionStatusWithContext:context];
}

static void log_message_cb(void *opdata, const char *message)
{
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(logMessage:)]) {
        [otrKit.delegate logMessage:[NSString stringWithUTF8String:message]];
    }
}

static int max_message_size_cb(void *opdata, ConnContext *context)
{
    /*Although the maximum message size depends on a number of factors, we
     found experimentally that the following rough values based solely on the
     (pidgin) protocol name work well:
     "prpl-msn",   1409
     "prpl-icq",   2346
     "prpl-aim",   2343
     "prpl-yahoo", 832
     "prpl-gg",    1999
     "prpl-irc",   417
     "prpl-oscar", 2343
     */
    /*void* lookup_result = g_hash_table_lookup(mms_table, context->protocol);
     if (!lookup_result)
     return 0;
     else
     return *((int*)lookup_result);*/
    
    OTRKit *otrKit = [OTRKit sharedInstance];
    if (otrKit.delegate && [otrKit.delegate respondsToSelector:@selector(maxMessageSizeForProtocol:)]) {
        return [otrKit.delegate maxMessageSizeForProtocol:[NSString stringWithUTF8String:context->protocol]];
    }
    
    if(context->protocol)
    {
        NSString *protocol = [NSString stringWithUTF8String:context->protocol];
        
        if([protocol isEqualToString:@"prpl-oscar"])
            return 2343;
    }
    return 0;
}

static OtrlMessageAppOps ui_ops = {
    policy_cb,
    create_privkey_cb,
    is_logged_in_cb,
    inject_message_cb,
    notify_cb,
    display_otr_message_cb,
    update_context_list_cb,
    protocol_name_cb,
    protocol_name_free_cb,
    confirm_fingerprint_cb,
    write_fingerprints_cb,
    gone_secure_cb,
    gone_insecure_cb,
    still_secure_cb,
    log_message_cb,
    max_message_size_cb,
    NULL,                   /* account_name */
    NULL                    /* account_name_free */
};

-(id)init
{
    if(self = [super init])
    {
        // initialize OTR
        OTRL_INIT;
        userState = otrl_userstate_create();
        
        FILE *privf;
        NSString *path = [self privateKeyPath];
        privf = fopen([path UTF8String], "rb");
        
        if(privf)
            otrl_privkey_read_FILEp(userState, privf);
        fclose(privf);
        
        FILE *storef;
        path = [self fingerprintsPath];
        storef = fopen([path UTF8String], "rb");
        
        if (storef)
            otrl_privkey_read_fingerprints_FILEp(userState, storef, NULL, NULL);
        fclose(storef);
    }
    
    return self;
}

- (NSString*) documentsDirectory {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  return documentsDirectory;
}

- (NSString*) privateKeyPath {
  return [[self documentsDirectory] stringByAppendingPathComponent:PRIVKEYFNAME];
}

- (NSString*) fingerprintsPath {
  return [[self documentsDirectory] stringByAppendingPathComponent:STOREFNAME];
}

- (NSString*) decodeMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol 
{
    int ignore_message;
    char *newmessage = NULL;
        
    ignore_message = otrl_message_receiving(userState, &ui_ops, NULL,[accountName UTF8String], [protocol UTF8String], [recipient UTF8String], [message UTF8String], &newmessage, NULL, NULL, NULL);
    NSString *newMessage = nil;
    
    if(ignore_message == 0)
    {
        
        if(newmessage)
        {
            newMessage = [NSString stringWithUTF8String:newmessage];
        }
        else
            newMessage = message;
    }
    else
    {
        otrl_message_free(newmessage);
        return nil;
    }
    
    otrl_message_free(newmessage);
    
    return newMessage;
}


- (NSString*) encodeMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol 
{
    gcry_error_t err;
    char *newmessage = NULL;
    
    err = otrl_message_sending(userState, &ui_ops, NULL,
                               [accountName UTF8String], [protocol UTF8String], [recipient UTF8String], [message UTF8String], NULL, &newmessage,
                               NULL, NULL);
    NSString *newMessage = nil;
    //NSLog(@"newmessage char: %s",newmessage);
    if(newmessage)
        newMessage = [NSString stringWithUTF8String:newmessage];
    else
        newMessage = @"";
    
    otrl_message_free(newmessage);
    
    return newMessage;
}

- (NSString*) fingerprintForAccountName:(NSString*)accountName protocol:(NSString*) protocol {
    NSString *fingerprintString = nil;
    char our_hash[45];
    otrl_privkey_fingerprint(userState, our_hash, [accountName UTF8String], [protocol UTF8String]);
    fingerprintString = [NSString stringWithUTF8String:our_hash];
    return fingerprintString;
}

- (ConnContext*) contextForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*) protocol {
    ConnContext *context = otrl_context_find(userState, [username UTF8String], [accountName UTF8String], [protocol UTF8String],NO,NULL,NULL, NULL);
    return context;
}

- (NSString *) fingerprintForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*) protocol {
    ConnContext *context = [self contextForUsername:username accountName:accountName protocol:protocol];
    NSString *fingerprintString = nil;
    if(context)
    {
        char their_hash[45];
        
        Fingerprint *fingerprint = context->active_fingerprint;
        
        if(fingerprint && fingerprint->fingerprint) {
            otrl_privkey_hash_to_human(their_hash, fingerprint->fingerprint);
            fingerprintString = [NSString stringWithUTF8String:their_hash];
        }
    }
    return fingerprintString;
}

- (OTRKitMessageState) messageStateForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*) protocol {
    ConnContext *context = [self contextForUsername:username accountName:accountName protocol:protocol];
    OTRKitMessageState messageState = kOTRKitMessageStatePlaintext;
    if (context) {
        switch (context->msgstate) {
            case OTRL_MSGSTATE_ENCRYPTED:
                messageState = kOTRKitMessageStateEncrypted;
                break;
            case OTRL_MSGSTATE_FINISHED:
                messageState = kOTRKitMessageStateFinished;
                break;
            case OTRL_MSGSTATE_PLAINTEXT:
                messageState = kOTRKitMessageStatePlaintext;
                break;
            default:
                messageState = kOTRKitMessageStatePlaintext;
                break;
        }
    }
    return messageState;
}


#pragma mark -
#pragma mark Singleton Object Methods

+ (OTRKit *) sharedInstance {
  static dispatch_once_t pred;
  static OTRKit *shared = nil;
  
  dispatch_once(&pred, ^{
    shared = [[OTRKit alloc] init];
  });
  return shared;
}

@end