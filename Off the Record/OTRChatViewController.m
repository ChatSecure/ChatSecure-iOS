//
//  OTRChatViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRChatViewController.h"
#import "OTREncryptionManager.h"
#import "DTLinkButton.h"
#import "privkey.h"

@implementation OTRChatViewController
@synthesize chatHistoryTextView;
@synthesize messageTextField;
@synthesize buddyListController;
@synthesize rawChatHistory;
@synthesize protocolManager;
@synthesize protocol;
@synthesize accountName;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
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

-(void)setupLockButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *buttonImage = [UIImage imageNamed:@"Lock_Locked.png"];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    CGRect buttonFrame = [button frame];
    buttonFrame.size.width = buttonImage.size.width;
    buttonFrame.size.height = buttonImage.size.height;
    [button setFrame:buttonFrame];
    [button addTarget:self action:@selector(lockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    lockButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonImage = [UIImage imageNamed:@"Lock_Unlocked.png"];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    buttonFrame = [button frame];
    buttonFrame.size.width = buttonImage.size.width;
    buttonFrame.size.height = buttonImage.size.height;
    [button setFrame:buttonFrame];
    [button addTarget:self action:@selector(lockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    unlockedButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [self refreshLockButton];
}

-(void)refreshLockButton
{
    if(context)
    {
        if(context->msgstate == OTRL_MSGSTATE_ENCRYPTED)
            self.navigationItem.rightBarButtonItem = lockButton;
        else
            self.navigationItem.rightBarButtonItem = unlockedButton;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = unlockedButton;
    }
}

-(void)lockButtonPressed
{
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Verify", nil];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    popupQuery.tag = 420;
    [popupQuery showFromTabBar:self.tabBarController.tabBar];
    [popupQuery release];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [messageTextField becomeFirstResponder];
    
    CGRect frame = CGRectMake(0.0, 0.0, 320, 142);

    chatHistoryTextView = [[DTAttributedTextView alloc] initWithFrame:frame];
	chatHistoryTextView.textDelegate = self;
	chatHistoryTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:chatHistoryTextView];
    
    if(!rawChatHistory)
        rawChatHistory = [[NSMutableString alloc] init];
     
	
	// Create attributed string from HTML
	CGSize maxImageSize = CGSizeMake(self.view.bounds.size.width - 20.0, self.view.bounds.size.height - 20.0);
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], NSTextSizeMultiplierDocumentOption, [NSValue valueWithCGSize:maxImageSize], DTMaxImageSize,
                             @"Helvetica", DTDefaultFontFamily,  @"purple", DTDefaultLinkColor, nil]; // @"green",DTDefaultTextColor,
   
    NSData *data = [rawChatHistory dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL];
	
	// Display string
	chatHistoryTextView.contentView.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
	chatHistoryTextView.attributedString = string;
    chatHistoryTextView.userInteractionEnabled = YES;
    
    
    
    NSString* secureNotification = [NSString stringWithFormat:@"%@_gone_secure",self.title];
    NSString* insecureNotification = [NSString stringWithFormat:@"%@_gone_insecure",self.title];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:) 
                                                 name:secureNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:) 
                                                 name:insecureNotification
                                               object:nil];
    if(!protocolManager)
        protocolManager = [OTRProtocolManager sharedInstance];
    
    context = otrl_context_find(protocolManager.encryptionManager.userState, [self.title UTF8String],[accountName UTF8String], [protocol UTF8String],NO,NULL,NULL, NULL);
    
    [self setupLockButton];
    

}

- (void) receiveNotification:(NSNotification *) notification
{
    NSString* secureNotification = [NSString stringWithFormat:@"%@_gone_secure",self.title];
    NSString* insecureNotification = [NSString stringWithFormat:@"%@_gone_insecure",self.title];
    NSLog(@"received notification: %@",[notification name]);
    
    if ([[notification name] isEqualToString:secureNotification])
    {
        self.navigationItem.rightBarButtonItem = lockButton;
        
    }
    else if([[notification name] isEqualToString:insecureNotification])
    {
        self.navigationItem.rightBarButtonItem = unlockedButton;
    }
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

    
    textField.text = @"";
    
    return YES;
}

-(void)updateChatHistory
{
    // Create attributed string from HTML
	CGSize maxImageSize = CGSizeMake(self.view.bounds.size.width - 20.0, self.view.bounds.size.height - 20.0);
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], NSTextSizeMultiplierDocumentOption, [NSValue valueWithCGSize:maxImageSize], DTMaxImageSize,
                             @"Helvetica", DTDefaultFontFamily,  @"purple", DTDefaultLinkColor, nil]; // @"green",DTDefaultTextColor,
    
    NSData *data = [rawChatHistory dataUsingEncoding:NSUTF8StringEncoding];
	NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:NULL];
    chatHistoryTextView.attributedString = string;

}

-(void)sendMessage:(NSString *)message
{
    OTRBuddyList * buddyList = protocolManager.buddyList;
    OTRBuddy* theBuddy = [buddyList getBuddyByName:self.title];
    
    OTRMessage *newMessage = [OTRMessage messageWithSender:accountName recipient:theBuddy.accountName message:message protocol:protocol];
    
    OTRMessage *encodedMessage = [OTRCodec encodeMessage:newMessage];
    
    [OTRMessage sendMessage:encodedMessage];    
    
    NSString *username = @"<FONT SIZE=16 COLOR=\"#0000ff\"><b>Me:</b></FONT>";
    
    [rawChatHistory appendFormat:@"%@ <FONT SIZE=16>%@</FONT><br>",username, message];
    
    [self updateChatHistory];
    [self scrollTextViewToBottom];
}

-(void)receiveMessage:(NSString *)message
{
    NSLog(@"received: %@",message);
    if(!rawChatHistory)
        rawChatHistory = [[NSMutableString alloc] init];
    
    NSRange htmlStart = [message rangeOfString:@"<HTML>"];
    
    NSString *username = [NSString stringWithFormat:@"<FONT SIZE=16 COLOR=\"#ff0000\"><b>%@:</b></FONT>",self.title];
    
    if(htmlStart.location == NSNotFound)
    {
        [rawChatHistory appendFormat:@"%@ <FONT SIZE=16>%@</FONT><br>",username,message];
    }
    else
    {
        //<HTML><BODY BGCOLOR="#ffffff"> is 30 characters
        NSString *substr = [message substringFromIndex:30];
        NSRange htmlEnd = [substr rangeOfString:@"</BODY>"];

        NSString *substr2 = [substr substringToIndex:htmlEnd.location];
        
        [rawChatHistory appendFormat:@"%@ %@<br>",username,substr2];
        
        NSLog(@"Stripped: %@",substr2);

    }
    
    
    [self updateChatHistory];
    [self scrollTextViewToBottom];

}

-(void)scrollTextViewToBottom
{
    //CGPoint bottomOffset = CGPointMake(0, [chatHistoryTextView contentSize].height);
    //[chatHistoryTextView setContentOffset: bottomOffset animated: YES];
    
    
    //textView.selectedRange = NSMakeRange(textView.text.length - 1, 0);
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}

#pragma mark Custom Views on Text
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForLink:(NSURL *)url identifier:(NSString *)identifier frame:(CGRect)frame
{
	DTLinkButton *button = [[[DTLinkButton alloc] initWithFrame:frame] autorelease];
	button.url = url;
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
	button.guid = identifier;
	
	// use normal push action for opening URL
	[button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
	
	// demonstrate combination with long press
	UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkLongPressed:)] autorelease];
	[button addGestureRecognizer:longPress];
	
	return button;
}

- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForAttachment:(DTTextAttachment *)attachment frame:(CGRect)frame
{
	
	return nil;
}


#pragma mark Actions

- (void)linkPushed:(DTLinkButton *)button
{
	[[UIApplication sharedApplication] openURL:[button.url absoluteURL]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		[[UIApplication sharedApplication] openURL:[lastActionLink absoluteURL]];
	}
    
    if(actionSheet.tag == 420)
    {
        if (buttonIndex == 0) // Verify
        {
            if(!context)
            {
                context = otrl_context_find(protocolManager.encryptionManager.userState, [self.title UTF8String],[buddyListController.protocolManager.oscarManager.accountName UTF8String], [protocol UTF8String],NO,NULL,NULL, NULL);
            }
            if(context)
            {
                char our_hash[45], their_hash[45];
                
                Fingerprint *fingerprint = context->active_fingerprint;
                
                otrl_privkey_fingerprint(protocolManager.encryptionManager.userState, our_hash, context->accountname, context->protocol);
                
                otrl_privkey_hash_to_human(their_hash, fingerprint->fingerprint);
                
                NSString *msg = [NSString stringWithFormat:@"Fingerprint for you, %s:\n%s\n\nPurported fingerprint for %s:\n%s\n", context->accountname, our_hash, context->username, their_hash];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Verify Fingerprint" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                [alert release];
            }
            
        } 
        else if (buttonIndex == 1) // Cancel
        {
            
        } 
    }
}

- (void)linkLongPressed:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		DTLinkButton *button = (id)[gesture view];
		button.highlighted = NO;
		lastActionLink = button.url;
		
		if ([[UIApplication sharedApplication] canOpenURL:[button.url absoluteURL]])
		{
			UIActionSheet *action = [[[UIActionSheet alloc] initWithTitle:[[button.url absoluteURL] description] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", nil] autorelease];
			[action showFromTabBar:self.tabBarController.tabBar];
		}
	}
}

-(void)viewWillAppear:(BOOL)animated
{
    if(!context)
    {
        context = otrl_context_find(protocolManager.encryptionManager.userState, [self.title UTF8String],[buddyListController.protocolManager.oscarManager.accountName UTF8String], [protocol UTF8String],NO,NULL,NULL, NULL);
    }
    [self refreshLockButton];
}

/*- (void)debugButton:(UIBarButtonItem *)sender
{
	_textView.contentView.drawDebugFrames = !_textView.contentView.drawDebugFrames;
	[DTCoreTextLayoutFrame setShouldDrawDebugFrames:_textView.contentView.drawDebugFrames];
	[self.view setNeedsDisplay];
}*/


@end
