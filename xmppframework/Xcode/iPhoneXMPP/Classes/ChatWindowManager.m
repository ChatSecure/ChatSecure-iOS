#import "ChatWindowManager.h"
#import "ChatViewController.h"
#import "XMPP.h"
#import "XMPPRoster.h"
#import "iPhoneXMPPAppDelegate.h"


@implementation ChatWindowManager

@synthesize activeChatController;
@synthesize backgroundMessage;
@synthesize backgroundStream;

- (iPhoneXMPPAppDelegate *)appDelegate
{
	return (iPhoneXMPPAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (ChatViewController *)chatControllerForJID:(XMPPJID *)jid matchResource:(BOOL)matchResource
{
    if(!chatControllers)
    {
        chatControllers = [[NSMutableDictionary alloc] initWithCapacity:3];
    }

    NSLog(@"get controller: %@", [jid bare]);

    ChatViewController *chatController = [chatControllers objectForKey:[jid bare]];
    return chatController;
}

- (void)openChatWindowWithStream:(XMPPStream *)xmppStream forUser:(id <XMPPUser>)user
{
	ChatViewController *cc = [self chatControllerForJID:[user jid] matchResource:NO];
	
	if(!cc)
	{
		// Create Manual Sync Window
		XMPPJID *jid = [[user primaryResource] jid];
		
		cc = [[ChatViewController alloc] initWithStream:xmppStream jid:jid];
        cc.chatManager = self;
        [chatControllers setObject:cc forKey:[jid bare]];
        NSLog(@"open window: %@", [jid bare]);
		
		// Note: ChatController will automatically release itself when the user closes the window
	}
    
    iPhoneXMPPAppDelegate *delegate = [self appDelegate];
    activeChatController = cc;
    NSArray *viewControllers = [NSArray arrayWithObjects:delegate.rootController, cc, nil];
    [delegate.navigationController setViewControllers:viewControllers animated:YES];
}

- (void)handleChatMessage:(XMPPMessage *)message withStream:(XMPPStream *)xmppStream
{
	NSLog(@"ChatWindowManager: handleChatMessage");
	
	ChatViewController *cc = [self chatControllerForJID:[message from] matchResource:YES];
    XMPPJID *jid = [message from];
    
	if(!cc)
	{
		// Create new chat window
		
		cc = [[ChatViewController alloc] initWithStream:xmppStream jid:jid message:message];
        cc.chatManager = self;
        [chatControllers setObject:cc forKey:[jid bare]];
        NSLog(@"handle chat: %@", [jid bare]);

        
        //iPhoneXMPPAppDelegate *delegate = [[self class] appDelegate];
        //[delegate.navigationController pushViewController:cc animated:YES];
        
		// Note: ChatController will automatically release itself when the user closes the window.
	}
    
    if(cc != activeChatController)
    {
        backgroundMessage = message;
        backgroundStream = xmppStream;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[jid bare] message:[[message elementForName:@"body"] stringValue]  delegate:[self appDelegate] cancelButtonTitle:@"Ignore" otherButtonTitles:@"Reply", nil];
        [alert setTag:444];
        [alert show];
    }
}

@end
