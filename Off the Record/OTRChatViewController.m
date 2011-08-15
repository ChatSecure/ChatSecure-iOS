//
//  OTRChatViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRChatViewController.h"
#import "message.h"
#import "privkey.h"

#define PRIVKEYFNAME @"otr.private_key"
#define STOREFNAME @"otr.fingerprints"

@implementation OTRChatViewController
@synthesize chatHistoryTextView;
@synthesize messageTextField;
@synthesize buddyListController;

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
    
    AIMSessionManager *theSession = [[OTRBuddyListViewController AIMSession] retain];
    AIMMessage * msg = [AIMMessage messageWithBuddy:[theSession.session.buddyList buddyWithUsername:[NSString stringWithUTF8String:recipient]] message:[NSString stringWithUTF8String:message]];
	[theSession.messageHandler sendMessage:msg];

    [theSession release];
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unknown Fingerprint" message:[NSString stringWithFormat:@"%s: %s",username, fingerprint] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
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
    NSLog(@"gone secure");
}

static void gone_insecure_cb(void *opdata, ConnContext *context)
{
   // otrg_dialog_disconnected(context);
    NSLog(@"gone insecure");

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [messageTextField becomeFirstResponder];
}

- (void)viewDidUnload
{
    [self setChatHistoryTextView:nil];
    [self setMessageTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [chatHistoryTextView release];
    [messageTextField release];
    [super dealloc];
}
- (IBAction)sendButtonPressed:(id)sender {
    [self textFieldShouldReturn:messageTextField];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self sendMessage:textField.text];
    
    chatHistoryTextView.text = [chatHistoryTextView.text stringByAppendingString:[NSString stringWithFormat:@"\nMe: %@",textField.text]];
    [self scrollTextView:chatHistoryTextView];

    
    textField.text = @"";
    
    return YES;
}

-(void)sendMessage:(NSString *)message
{
    gcry_error_t err;
    char *newmessage = NULL;
    
    err = otrl_message_sending([OTRBuddyListViewController OTR_userState], &ui_ops, NULL,
                               [buddyListController.accountName UTF8String], "prpl-oscar", [self.title UTF8String], [message UTF8String], NULL, &newmessage,
                               NULL, NULL);
    NSString *newMessage = [NSString stringWithUTF8String:newmessage];
    
    NSLog(@"%@",newMessage);
    
    AIMSessionManager *theSession = [OTRBuddyListViewController AIMSession];
    AIMMessage * msg = [AIMMessage messageWithBuddy:[theSession.session.buddyList buddyWithUsername:self.title] message:newMessage];
	[theSession.messageHandler sendMessage:msg];
    
    otrl_message_free(newmessage);
}

-(void)receiveMessage:(NSString *)message
{
    int ignore_message;
    char *newmessage = NULL;
    
    ignore_message = otrl_message_receiving([OTRBuddyListViewController OTR_userState], &ui_ops, NULL,[buddyListController.accountName UTF8String], "prpl-oscar", [self.title UTF8String], [message UTF8String], &newmessage, NULL, NULL, NULL);
    
    NSLog(@"%@",message);

    if(ignore_message == 0)
    {
        NSString *newMessage;
        if(newmessage)
        {
            newMessage = [NSString stringWithUTF8String:newmessage];
        }
        else
            newMessage = message;
            
        chatHistoryTextView.text = [chatHistoryTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n%@: %@",self.title,newMessage]];
        
        [self scrollTextView:chatHistoryTextView];

    }
    
    otrl_message_free(newmessage);
}

-(void)scrollTextView: (UITextView *)textView
{
    textView.selectedRange = NSMakeRange(textView.text.length - 1, 0);
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}

@end
