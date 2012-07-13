//
//  OTRCodec.m
//  Off the Record
//
//  Created by Chris on 8/17/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRCodec.h"
#import "OTRBuddyListViewController.h"
#import "OTRProtocolManager.h"
#import "privkey.h"
#import "message.h"

#define PRIVKEYFNAME @"otr.private_key"
#define STOREFNAME @"otr.fingerprints"

@implementation OTRCodec

static OtrlPolicy policy_cb(void *opdata, ConnContext *context)
{
    return OTRL_POLICY_DEFAULT;
}

static const char *protocol_name_cb(void *opdata, const char *protocol)
{
    //return "prpl-oscar";
    //NSLog(@"protocol: %s",protocol);
    return protocol;
}

static void protocol_name_free_cb(void *opdata, const char *protocol_name)
{
    /* Do nothing, since we didn't actually allocate any memory in
     * protocol_name_cb. */
}

static void create_privkey_cb(void *opdata, const char *accountname,
                              const char *protocol)
{
    FILE *privf;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",PRIVKEYFNAME]];
    privf = fopen([path UTF8String], "w+b");
    
    //otrg_plugin_create_privkey(accountname, protocol);
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    [protocolManager.encryptionManager protectFileWithPath:path];
    
    
    otrl_privkey_generate_FILEp(protocolManager.encryptionManager.userState, privf, accountname, protocol);
    fclose(privf);
}

static int is_logged_in_cb(void *opdata, const char *accountname,
                           const char *protocol, const char *recipient)
{
    /*PurpleAccount *account;
     PurpleBuddy *buddy;
     
     account = purple_accounts_find(accountname, protocol);
     if (!account) return -1;
     
     buddy = purple_find_buddy(account, recipient);
     if (!buddy) return -1;
     
     return (PURPLE_BUDDY_IS_ONLINE(buddy));*/
    return -1;
}

static void inject_message_cb(void *opdata, const char *accountname,
                              const char *protocol, const char *recipient, const char *message)
{
    /*PurpleAccount *account = purple_accounts_find(accountname, protocol);
     if (!account) {
     PurplePlugin *p = purple_find_prpl(protocol);
     char *msg = g_strdup_printf(_("Unknown account %s (%s)."),
     accountname,
     (p && p->info->name) ? p->info->name : _("Unknown"));
     otrg_dialog_notify_error(accountname, protocol, recipient,
     _("Unknown account"), msg, NULL);
     g_free(msg);
     return;
     }
     otrg_plugin_inject_message(account, recipient, message);*/
    if(accountname && recipient && message && protocol)
    {
        
        OTRMessage *newMessage = [OTRMessage messageWithBuddy:[[OTRProtocolManager sharedInstance] buddyForUserName:[NSString stringWithUTF8String:recipient] accountName:[NSString stringWithUTF8String:accountname] protocol:[NSString stringWithUTF8String:protocol ] ] message:[NSString stringWithUTF8String:message]];
        
        
        [newMessage send];
    }

    
    //NSLog(@"sent inject: %s",message);
    
}


static void notify_cb(void *opdata, OtrlNotifyLevel level,
                      const char *accountname, const char *protocol, const char *username,
                      const char *title, const char *primary, const char *secondary)
{
    /*PurpleNotifyMsgType purplelevel = PURPLE_NOTIFY_MSG_ERROR;
     
     switch (level) {
     case OTRL_NOTIFY_ERROR:
     purplelevel = PURPLE_NOTIFY_MSG_ERROR;
     break;
     case OTRL_NOTIFY_WARNING:
     purplelevel = PURPLE_NOTIFY_MSG_WARNING;
     break;
     case OTRL_NOTIFY_INFO:
     purplelevel = PURPLE_NOTIFY_MSG_INFO;
     break;
     }
     
     otrg_dialog_notify_message(purplelevel, accountname, protocol,
     username, title, primary, secondary);*/
}

static int display_otr_message_cb(void *opdata, const char *accountname,
                                  const char *protocol, const char *username, const char *msg)
{
    /*return otrg_dialog_display_otr_message(accountname, protocol,
     username, msg);*/
    return 0;
}

static void update_context_list_cb(void *opdata)
{
    //otrg_ui_update_keylist();
}

static void confirm_fingerprint_cb(void *opdata, OtrlUserState us,
                                   const char *accountname, const char *protocol, const char *username,
                                   unsigned char fingerprint[20])
{
    //otrg_dialog_unknown_fingerprint(us, accountname, protocol, username,
    //                                fingerprint);
    /*NSMutableString *hex = [NSMutableString string];
    for (int i=0; i<20; i++)
        [hex appendFormat:@"%02x", fingerprint[i]];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unknown Fingerprint" message:[NSString stringWithFormat:@"%s: %@",username, hex] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];*/
    char our_hash[45], their_hash[45];
    
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    
    ConnContext *context = otrl_context_find(protocolManager.encryptionManager.userState, username,accountname, protocol,NO,NULL,NULL, NULL);
        
    otrl_privkey_fingerprint(protocolManager.encryptionManager.userState, our_hash, context->accountname, context->protocol);
    
    otrl_privkey_hash_to_human(their_hash, fingerprint);
    
    NSString *msg = [NSString stringWithFormat:@"Fingerprint for you, %s:\n%s\n\nPurported fingerprint for %s:\n%s\n", context->accountname, our_hash, context->username, their_hash];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Verify Fingerprint" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

static void write_fingerprints_cb(void *opdata)
{
    /*otrg_plugin_write_fingerprints();
     otrg_ui_update_keylist();
     otrg_dialog_resensitize_all();*/
    
    FILE *storef;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",STOREFNAME]];
    storef = fopen([path UTF8String], "wb");
    
    if (!storef) return;
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    [protocolManager.encryptionManager protectFileWithPath:path];

    
    otrl_privkey_write_fingerprints_FILEp(protocolManager.encryptionManager.userState, storef);
    fclose(storef);
}


static void gone_secure_cb(void *opdata, ConnContext *context)
{
    if(context->username)
    {
        NSString* username = [NSString stringWithUTF8String:context->username];
        NSString* accountname = [NSString stringWithUTF8String:context->accountname];
        NSString* protocol = [NSString stringWithUTF8String:context->protocol];
        OTRBuddy *buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:username accountName:accountname protocol:protocol];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"secure"];
        

        [[NSNotificationCenter defaultCenter] postNotificationName:ENCRYPTION_STATE_NOTIFICATION object:buddy userInfo:userInfo];
    }
}

static void gone_insecure_cb(void *opdata, ConnContext *context)
{
    // otrg_dialog_disconnected(context);
    //NSLog(@"gone insecure");
    if(context->username)
    {
        NSString* username = [NSString stringWithUTF8String:context->username];
        NSString* accountname = [NSString stringWithUTF8String:context->accountname];
        NSString* protocol = [NSString stringWithUTF8String:context->protocol];
        OTRBuddy *buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:username accountName:accountname protocol:protocol];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"secure"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ENCRYPTION_STATE_NOTIFICATION object:buddy userInfo:userInfo];
    }
}

static void still_secure_cb(void *opdata, ConnContext *context, int is_reply)
{
    if(context->username)
    {
        NSString* username = [NSString stringWithUTF8String:context->username];
        NSString* accountname = [NSString stringWithUTF8String:context->accountname];
        NSString* protocol = [NSString stringWithUTF8String:context->protocol];
        OTRBuddy *buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:username accountName:accountname protocol:protocol];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"secure"];
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ENCRYPTION_STATE_NOTIFICATION object:buddy userInfo:userInfo];
    }
}

static void log_message_cb(void *opdata, const char *message)
{
    //purple_debug_info("otr", message);
    //NSLog(@"otr: %s",message);
    
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

+(OTRMessage*) decodeMessage:(OTRMessage*)theMessage;
{
    int ignore_message;
    char *newmessage = NULL;
    
    NSString *message = theMessage.message;
    NSString *friendAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.protocol.account.protocol;
    NSString *myAccountName = theMessage.buddy.protocol.account.username;
    
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    
    OtrlUserState userstate = protocolManager.encryptionManager.userState;
    
    if(!userstate)
        NSLog(@"userstate is nil!");
    
    
    ignore_message = otrl_message_receiving(userstate, &ui_ops, NULL,[myAccountName UTF8String], [protocol UTF8String], [friendAccount UTF8String], [message UTF8String], &newmessage, NULL, NULL, NULL);
    //NSLog(@"ignore message: %d",ignore_message);
    NSString *newMessage;
    
    
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
    
    OTRMessage *newOTRMessage = [OTRMessage messageWithBuddy:theMessage.buddy message:newMessage];
    
    return newOTRMessage;
}


+(OTRMessage*) encodeMessage:(OTRMessage*)theMessage;
{
    gcry_error_t err;
    char *newmessage = NULL;
    
    NSString *message = theMessage.message;
    NSString *recipientAccount = theMessage.buddy.accountName;
    NSString *protocol = theMessage.buddy.protocol.account.protocol;
    NSString *sendingAccount = theMessage.buddy.protocol.account.username;
    //NSLog(@"inside encodeMessage: %@ %@ %@ %@",message,recipientAccount,protocol,sendingAccount);
    OTRProtocolManager *protocolManager = [OTRProtocolManager sharedInstance];
    
    err = otrl_message_sending(protocolManager.encryptionManager.userState, &ui_ops, NULL,
                               [sendingAccount UTF8String], [protocol UTF8String], [recipientAccount UTF8String], [message UTF8String], NULL, &newmessage,
                               NULL, NULL);
    NSString *newMessage;
    //NSLog(@"newmessage char: %s",newmessage);
    if(newmessage)
        newMessage = [NSString stringWithUTF8String:newmessage];
    else
        newMessage = @"";
    
    otrl_message_free(newmessage);
    
    OTRMessage *newOTRMessage = [OTRMessage messageWithBuddy:theMessage.buddy message:newMessage];
    
    return newOTRMessage;
}


@end
