//
//  OTRCodec.m
//  Off the Record
//
//  Created by Chris on 8/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRCodec.h"
#import "OTRBuddyListViewController.h"
#import "message.h"
#import "privkey.h"

#define PRIVKEYFNAME @"otr.private_key"
#define STOREFNAME @"otr.fingerprints"
#define ARC4RANDOM_MAX      0x100000000


@implementation OTRCodec

@synthesize accountName;

-(id)initWithAccountName:(NSString*)account
{
    if(self = [super init])
    {
        accountName = account;
    }
    return self;
}

static OtrlPolicy policy_cb(void *opdata, ConnContext *context)
{
    return OTRL_POLICY_DEFAULT;
}

static const char *protocol_name_cb(void *opdata, const char *protocol)
{
    return "prpl-oscar";
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
    otrl_privkey_generate_FILEp([OTRBuddyListViewController OTR_userState], privf, accountname, protocol);
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

    
    // use delay to prevent OSCAR rate-limiting problem
    double val = floorf(((double)arc4random() / ARC4RANDOM_MAX) * 100.0f);
    float delay = (val+50.0f)/100.0f;
    
    
    [OTRCodec sendMessage:[NSString stringWithUTF8String:message] toUser:[NSString stringWithUTF8String:recipient] withDelay:delay];
    
    NSLog(@"sent inject: %s",message);
    
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
    NSMutableString *hex = [NSMutableString string];
    for (int i=0; i<20; i++)
        [hex appendFormat:@"%02x", fingerprint[i]];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unknown Fingerprint" message:[NSString stringWithFormat:@"%s: %@",username, hex] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
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
    otrl_privkey_write_fingerprints_FILEp([OTRBuddyListViewController OTR_userState], storef);
    fclose(storef);
}

static void gone_secure_cb(void *opdata, ConnContext *context)
{
    //otrg_dialog_connected(context);
    //NSLog(@"gone secure");
    
    /*unsigned char* fingerprint = context->fingerprint_root.fingerprint;
    
    NSMutableString *hex = [NSMutableString string];
    for (int i=0; i<20; i++)
        [hex appendFormat:@"%02x", fingerprint[i]];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your  Fingerprint" message:[NSString stringWithFormat:@"%@", hex] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];*/
    
    NSString* username = [NSString stringWithUTF8String:context->username];
    NSString* notification = [NSString stringWithFormat:@"%@_gone_secure",username];
    
    NSLog(@"%@",notification);
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
}

static void gone_insecure_cb(void *opdata, ConnContext *context)
{
    // otrg_dialog_disconnected(context);
    //NSLog(@"gone insecure");
    
    NSString* username = [NSString stringWithUTF8String:context->username];
    NSString* notification = [NSString stringWithFormat:@"%@_gone_insecure",username];
    
    NSLog(@"%@",notification);
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
}

static void still_secure_cb(void *opdata, ConnContext *context, int is_reply)
{
    /*if (is_reply == 0) {
     otrg_dialog_stillconnected(context);
     }*/
    NSLog(@"still secure");
    
}

static void log_message_cb(void *opdata, const char *message)
{
    //purple_debug_info("otr", message);
    NSLog(@"otr: %s",message);
    
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
    return 2343;
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

-(NSString*) decodeMessage:(NSString*) message fromUser:(NSString*)friendAccount
{
    int ignore_message;
    char *newmessage = NULL;
    
    ignore_message = otrl_message_receiving([OTRBuddyListViewController OTR_userState], &ui_ops, NULL,[accountName UTF8String], "prpl-oscar", [friendAccount UTF8String], [message UTF8String], &newmessage, NULL, NULL, NULL);
    
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
    return newMessage;
}

-(NSString*) encodeMessage:(NSString*) message toUser:(NSString*)recipientAccount
{
    gcry_error_t err;
    char *newmessage = NULL;
    
    err = otrl_message_sending([OTRBuddyListViewController OTR_userState], &ui_ops, NULL,
                               [accountName UTF8String], "prpl-oscar", [recipientAccount UTF8String], [message UTF8String], NULL, &newmessage,
                               NULL, NULL);
    NSString *newMessage = [NSString stringWithUTF8String:newmessage];
    
    otrl_message_free(newmessage);
    
    return newMessage;
}

+(void)sendMessage:(NSString*)message toUser:(NSString*)recipient withDelay:(float)delay
{
    
    
    AIMSessionManager *theSession = [[OTRBuddyListViewController AIMSession] retain];
    AIMMessage * msg = [AIMMessage messageWithBuddy:[theSession.session.buddyList buddyWithUsername:recipient] message:message];
    
    // use delay to prevent OSCAR rate-limiting problem
    NSDate *future = [NSDate dateWithTimeIntervalSinceNow: delay ];
    [NSThread sleepUntilDate:future];
    
	[theSession.messageHandler sendMessage:msg];
    
    [theSession release];
    
}



@end
