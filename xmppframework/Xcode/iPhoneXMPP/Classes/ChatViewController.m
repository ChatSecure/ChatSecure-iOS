#import "ChatViewController.h"
#import "XMPP.h"

@interface ChatViewController (PrivateAPI)
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message;
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation ChatViewController

@synthesize xmppStream;
@synthesize jid;
@synthesize messageView;
@synthesize messageField;
@synthesize chatManager;

- (id)initWithStream:(XMPPStream *)stream jid:(XMPPJID *)fullJID
{
	return [self initWithStream:stream jid:fullJID message:nil];
}

- (id)initWithStream:(XMPPStream *)stream jid:(XMPPJID *)fullJID message:(XMPPMessage *)message
{
	if(self = [super init])
	{
		xmppStream = [stream retain];
		jid = [fullJID retain];
		
		firstMessage = [message retain];
	}
	return self;
}

-(void)viewDidLoad
{
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	
	messageView.text = @"";
	
    self.title = [jid full];
    
	[messageField becomeFirstResponder];
	
	if(firstMessage)
	{
		[self xmppStream:xmppStream didReceiveMessage:firstMessage];
		[firstMessage release];
		firstMessage  = nil;
	}
}

-(void)viewDidDisappear:(BOOL)animated
{
    chatManager.activeChatController = nil;
    [xmppStream removeDelegate:self delegateQueue:dispatch_get_main_queue()];
}

/**
 * Called immediately before the window closes.
 * 
 * This method's job is to release the WindowController (self)
 * This is so that the nib file is released from memory.
 **/
- (void)windowWillClose:(NSNotification *)aNotification
{
	NSLog(@"ChatController: windowWillClose");
	
	[xmppStream removeDelegate:self];
	[self autorelease];
}

- (void)dealloc
{
	NSLog(@"Destroying self: %@", self);
	
	[xmppStream release];
	[jid release];
	[firstMessage release];
	
    [messageView release];
    [messageField release];
	[super dealloc];
}

- (void)scrollToBottom
{
	/*NSScrollView *scrollView = [messageView enclosingScrollView];
	NSPoint newScrollOrigin;
	
	if ([[scrollView documentView] isFlipped])
		newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
	else
		newScrollOrigin = NSMakePoint(0.0F, 0.0F);
	
	[[scrollView documentView] scrollPoint:newScrollOrigin];*/
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	[messageField setEnabled:YES];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	if(![jid isEqual:[message from]]) return;
	
	if([message isChatMessageWithBody])
	{
		NSString *messageStr = [[message elementForName:@"body"] stringValue];
		
		NSString *paragraph = [NSString stringWithFormat:@"%@\n\n", messageStr];
		
		messageView.text = [messageView.text stringByAppendingString:paragraph];
	}
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	[messageField setEnabled:NO];
}

- (IBAction)sendMessage:(id)sender
{
	NSString *messageStr = messageField.text;
	
	if([messageStr length] > 0)
	{
		NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
		[body setStringValue:messageStr];
		
		NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
		[message addAttributeWithName:@"type" stringValue:@"chat"];
		[message addAttributeWithName:@"to" stringValue:[jid full]];
		[message addChild:body];
		
		[xmppStream sendElement:message];
		
		NSString *paragraph = [NSString stringWithFormat:@"%@\n\n", messageStr];
		
        messageView.text = [messageView.text stringByAppendingString:paragraph];
		
		[self scrollToBottom];
		
		messageField.text = @"";
	}
}

- (void)viewDidUnload {
    [self setMessageView:nil];
    [self setMessageField:nil];
    [super viewDidUnload];
}
@end
