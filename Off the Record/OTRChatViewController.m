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
#import "DTCoreTextConstants.h"
#import "privkey.h"
#import <QuartzCore/QuartzCore.h>
#import "DTHTMLAttributedStringBuilder.h"

#define kTabBarHeight 49
#define kSendButtonWidth 60

@implementation OTRChatViewController
@synthesize chatHistoryTextView;
@synthesize messageTextField;
@synthesize buddyListController;
@synthesize protocolManager;
@synthesize chatBoxView;
@synthesize context;
@synthesize lockButton, unlockedButton;
@synthesize lastActionLink;
@synthesize sendButton;
@synthesize keyboardIsShown;
@synthesize buddy;

- (void) dealloc {
    self.lastActionLink = nil;
    self.buddyListController = nil;
    self.buddy = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.chatHistoryTextView = nil;
    self.messageTextField = nil;
    self.lockButton = nil;
    self.unlockedButton = nil;
    self.chatBoxView = nil;
    self.sendButton = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        //set notification for when keyboard shows/hides
        self.title = @"Chat";
    }
    return self;
}

- (CGFloat) chatBoxViewHeight {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 50.0;
    } else {
        return 30.0;
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    NSValue* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = 0;
    [value getValue:&duration];
    return duration;
}

- (CGFloat)keyboardHeightForNotification:(NSNotification*)notification {
    // get the size of the keyboard
    NSDictionary* userInfo = [notification userInfo];

    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    return keyboardFrame.size.height;
}

- (void)keyboardWillHide:(NSNotification *)n
{
    // get the size of the keyboard
    CGFloat keyboardHeight = [self keyboardHeightForNotification:n];
    
    
    // resize the scrollview
    CGRect chatHistoryFrame = self.chatHistoryTextView.frame;
    CGRect chatBoxViewFrame = self.chatBoxView.frame;
    // I'm also subtracting a constant kTabBarHeight because my UIScrollView was offset by the UITabBar so really only the portion of the keyboard that is leftover pass the UITabBar is obscuring my UIScrollView.
    CGFloat offsetHeight = (keyboardHeight - kTabBarHeight);
    chatHistoryFrame.size.height += offsetHeight;
    chatBoxViewFrame.origin.y += offsetHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    // The kKeyboardAnimationDuration I am using is 0.3
    [UIView setAnimationDuration:[self keyboardAnimationDurationForNotification:n]];
    self.chatHistoryTextView.frame = chatHistoryFrame;
    self.chatBoxView.frame = chatBoxViewFrame;
    [UIView commitAnimations];
    
    keyboardIsShown = NO;
}

- (void)keyboardWillShow:(NSNotification *)n
{
    // This is an ivar I'm using to ensure that we do not do the frame size adjustment on the UIScrollView if the keyboard is already shown.  This can happen if the user, after fixing editing a UITextField, scrolls the resized UIScrollView to another UITextField and attempts to edit the next UITextField.  If we were to resize the UIScrollView again, it would be disastrous.  NOTE: The keyboard notification will fire even when the keyboard is already shown.
    if (keyboardIsShown) {
        return;
    }
        
    CGFloat keyboardHeight = [self keyboardHeightForNotification:n];


    
    // resize the scrollview
    CGRect chatHistoryFrame = self.chatHistoryTextView.frame;
    CGRect chatBoxViewFrame = self.chatBoxView.frame;
    // I'm also subtracting a constant kTabBarHeight because my UIScrollView was offset by the UITabBar so really only the portion of the keyboard that is leftover pass the UITabBar is obscuring my UIScrollView.
    CGFloat offsetHeight = (keyboardHeight - kTabBarHeight);
    chatHistoryFrame.size.height -= offsetHeight;
    chatBoxViewFrame.origin.y -= offsetHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    // The kKeyboardAnimationDuration I am using is 0.3
    [UIView setAnimationDuration:[self keyboardAnimationDurationForNotification:n]];
    self.chatHistoryTextView.frame = chatHistoryFrame;
    self.chatBoxView.frame = chatBoxViewFrame;
    [UIView commitAnimations];
    
    keyboardIsShown = YES;
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
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Initiate Encrypted Chat", @"Verify", nil];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    popupQuery.tag = 420;
    [popupQuery showFromTabBar:self.tabBarController.tabBar];
}



#pragma mark - View lifecycle

- (void) loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.chatBoxView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:chatBoxView];
    
    self.messageTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    messageTextField.borderStyle = UITextBorderStyleRoundedRect;
    messageTextField.delegate = self;
    [self.chatBoxView addSubview:messageTextField];

    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.chatBoxView addSubview:sendButton];
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //[messageTextField becomeFirstResponder];
    //[chatBox.layer setCornerRadius:5];
    //[chatBox setContentInset:UIEdgeInsetsZero];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:self.view.window];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:self.view.window];
    keyboardIsShown = NO;
    //make contentSize bigger than your scrollSize (you will need to figure out for your own use case)

    
    CGRect frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height-[self chatBoxViewHeight]-kTabBarHeight-self.navigationController.navigationBar.frame.size.height);

    [DTAttributedTextContentView setLayerClass:[CATiledLayer class]];
    self.chatHistoryTextView = [[DTAttributedTextView alloc] initWithFrame:frame];
	chatHistoryTextView.textDelegate = self;
	chatHistoryTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:chatHistoryTextView];
    self.chatBoxView.frame = CGRectMake(0, self.chatHistoryTextView.frame.size.height, self.view.frame.size.width, [self chatBoxViewHeight]);
    
    self.messageTextField.frame = CGRectMake(0, 0, self.view.frame.size.width-kSendButtonWidth, self.chatBoxView.frame.size.height);
    self.sendButton.frame = CGRectMake(self.messageTextField.frame.size.width, 0, kSendButtonWidth , self.chatBoxView.frame.size.height);
    
    self.chatBoxView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    messageTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	
	// Create attributed string from HTML
	CGSize maxImageSize = CGSizeMake(self.view.bounds.size.width - 20.0, self.view.bounds.size.height - 20.0);
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], NSTextSizeMultiplierDocumentOption, [NSValue valueWithCGSize:maxImageSize], DTMaxImageSize,
                             @"Helvetica", DTDefaultFontFamily,  @"purple", DTDefaultLinkColor, nil]; // @"green",DTDefaultTextColor,
   
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:nil];

	
	// Display string
	chatHistoryTextView.contentView.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
	chatHistoryTextView.attributedString = string;
    chatHistoryTextView.userInteractionEnabled = YES;
    
    if(!protocolManager)
        protocolManager = [OTRProtocolManager sharedInstance];
    
    
    [self setupLockButton];
    
    
    
    //set notification for when a key is pressed.
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector: @selector(keyPressed:) 
                                                 name: UITextViewTextDidChangeNotification 
                                               object: nil];
    
    //turn off scrolling and set the font details.
    //chatBox.scrollEnabled = NO;
    //chatBox.font = [UIFont fontWithName:@"Helvetica" size:14]; 
}

- (void) refreshContext {
    self.context = otrl_context_find(protocolManager.encryptionManager.userState, [buddy.accountName UTF8String],[[self.protocolManager accountNameForProtocol:buddy.protocol] UTF8String], [buddy.protocol UTF8String],NO,NULL,NULL, NULL);
}

- (void) setBuddy:(OTRBuddy *)newBuddy {
    if(buddy) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ENCRYPTION_STATE_NOTIFICATION object:buddy];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MESSAGE_RECEIVED_NOTIFICATION object:buddy];
    }
    
    buddy = newBuddy;
    self.title = newBuddy.displayName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encryptionStateChangeNotification:) name:ENCRYPTION_STATE_NOTIFICATION object:buddy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceivedNotification:) name:MESSAGE_RECEIVED_NOTIFICATION object:buddy];
    
    [self refreshContext];
    [self refreshLockButton];
    [self updateChatHistory];
}
     
     
- (void) messageReceivedNotification:(NSNotification*)notification {
    [self updateChatHistory];
}


-(void) keyPressed: (NSNotification*) notification{
/*	// get the size of the text block so we can work our magic
	//CGSize newSize = [chatBox.text 
    //                  sizeWithFont:[UIFont fontWithName:@"Helvetica" size:14] 
    //                  constrainedToSize:CGSizeMake(222,9999) 
    //                  lineBreakMode:UILineBreakModeWordWrap];
    //CGSize newSize = chatBox.contentSize.height;
	NSInteger newSizeH = chatBox.contentSize.height-12;
	NSInteger newSizeW = chatBox.contentSize.width;
    
    // I output the new dimensions to the console 
    // so we can see what is happening
	NSLog(@"NEW SIZE : %d X %d", newSizeW, newSizeH);
	if (chatBox.hasText)
	{
        // if the height of our new chatbox is
        // below 90 we can set the height
		if (newSizeH <= 90)
		{
			[chatBox scrollRectToVisible:CGRectMake(0,0,1,1) animated:NO];
            
			// chatbox
			CGRect chatBoxFrame = chatBox.frame;
			NSInteger chatBoxH = chatBoxFrame.size.height;
			NSInteger chatBoxW = chatBoxFrame.size.width;
			NSLog(@"CHAT BOX SIZE : %d X %d", chatBoxW, chatBoxH);
			chatBoxFrame.size.height = newSizeH + 12;
			chatBox.frame = chatBoxFrame;
            
			// form view
			CGRect formFrame = chatBoxView.frame;
			NSInteger viewFormH = formFrame.size.height;
			NSLog(@"FORM VIEW HEIGHT : %d", viewFormH);
			formFrame.size.height = 30 + newSizeH;
			formFrame.origin.y = 199 - (newSizeH - 18)-49;
			chatBoxView.frame = formFrame;
            
			// table view
			CGRect tableFrame = chatHistoryTextView.frame;
			NSInteger viewTableH = tableFrame.size.height;
			NSLog(@"TABLE VIEW HEIGHT : %d", viewTableH);
			//tableFrame.size.height = 199 - (newSizeH - 18);
            tableFrame.size.height = 199 - (newSizeH - 18)-49;
			chatHistoryTextView.frame = tableFrame;
		}
        
        // if our new height is greater than 90
        // sets not set the height or move things
        // around and enable scrolling
		if (newSizeH > 90)
		{
			chatBox.scrollEnabled = YES;
		}
	}*/
}
- (void)chatButtonClick 
{
/*	// hide the keyboard, we are done with it.
	//[chatBox resignFirstResponder];
	//chatBox.text = nil;
    
	// chatbox
	CGRect chatBoxFrame = chatBox.frame;
	chatBoxFrame.size.height = 34;
	chatBox.frame = chatBoxFrame;
    
	// form view
	//CGRect formFrame = viewChatBox.frame;
	//formFrame.size.height = 45;
	//formFrame.origin.y = 415;
	//viewChatBox.frame = formFrame;
    
	// table view
	//CGRect tableFrame = viewChatHistory.frame;
	//tableFrame.size.height = 415;
	//viewChatHistory.frame = tableFrame;
    
    // form view
    CGRect formFrame = chatBoxView.frame;
    //NSInteger viewFormH = formFrame.size.height;
    //NSLog(@"FORM VIEW HEIGHT : %d", viewFormH);
    //formFrame.size.height = 30 + 12;
    formFrame.size.height = 52;
    //formFrame.origin.y = 199 - (12 - 18)-49;
    formFrame.origin.y = 146;
    chatBoxView.frame = formFrame;
    
    // table view
    CGRect tableFrame = chatHistoryTextView.frame;
    //NSInteger viewTableH = tableFrame.size.height;
    //NSLog(@"TABLE VIEW HEIGHT : %d", viewTableH);
    //tableFrame.size.height = 199 - (newSizeH - 18);
    tableFrame.size.height = 146;
    chatHistoryTextView.frame = tableFrame;
 */
}

- (void) encryptionStateChangeNotification:(NSNotification *) notification
{
    NSLog(@"received notification: %@",[notification name]);
    NSDictionary *userInfo = notification.userInfo;
    BOOL isSecure = [[userInfo objectForKey:@"secure"] boolValue];
    
    if (isSecure)
    {
        self.navigationItem.rightBarButtonItem = lockButton;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = unlockedButton;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [textField resignFirstResponder];
    } else {
        [self sendButtonPressed:nil];
    }
    return YES;
}


- (void)sendButtonPressed:(id)sender {
    BOOL secure = self.navigationItem.rightBarButtonItem == lockButton;
    [buddy sendMessage:messageTextField.text secure:secure];
    messageTextField.text = @"";    
    [self chatButtonClick];
    [self updateChatHistory];
}


-(void)updateChatHistory
{
    // Create attributed string from HTML
	CGSize maxImageSize = CGSizeMake(self.view.bounds.size.width - 20.0, self.view.bounds.size.height - 20.0);
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], NSTextSizeMultiplierDocumentOption, [NSValue valueWithCGSize:maxImageSize], DTMaxImageSize,
                             @"Helvetica", DTDefaultFontFamily,  @"purple", DTDefaultLinkColor, nil]; // @"green",DTDefaultTextColor,
    
    NSData *data = [buddy.chatHistory dataUsingEncoding:NSUTF8StringEncoding];
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:nil];
    
    chatHistoryTextView.attributedString = string;
}


-(void)scrollTextViewToBottom
{
    //CGPoint bottomOffset = CGPointMake(0, [chatHistoryTextView contentSize].height);
    //[chatHistoryTextView setContentOffset: bottomOffset animated: YES];
    //textView.selectedRange = NSMakeRange(textView.text.length - 1, 0);
    //NSLog(@"chat history text view height: %f",[chatHistoryTextView contentSize].height);
    CGRect bottomRect = CGRectMake(0, 0, 1, [chatHistoryTextView contentSize].height);
    [chatHistoryTextView scrollRectToVisible: bottomRect animated:YES];
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}

#pragma mark Custom Views on Text
- (UIView *)attributedTextContentView:(DTAttributedTextContentView *)attributedTextContentView viewForLink:(NSURL *)url identifier:(NSString *)identifier frame:(CGRect)frame
{
	DTLinkButton *button = [[DTLinkButton alloc] initWithFrame:frame];
	button.url = url;
	button.minimumHitSize = CGSizeMake(25, 25); // adjusts it's bounds so that button is always large enough
	button.guid = identifier;
	
	// use normal push action for opening URL
	[button addTarget:self action:@selector(linkPushed:) forControlEvents:UIControlEventTouchUpInside];
	
	// demonstrate combination with long press
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkLongPressed:)];
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
    NSLog(@"buttonIndex: %d",buttonIndex);
    if(actionSheet.tag == 420)
    {
        if (buttonIndex == 1) // Verify
        {
            [self refreshContext];
            if(context)
            {
                char our_hash[45], their_hash[45];
                
                Fingerprint *fingerprint = context->active_fingerprint;
                
                otrl_privkey_fingerprint(protocolManager.encryptionManager.userState, our_hash, context->accountname, context->protocol);
                NSString *msg = nil;
                if(fingerprint && fingerprint->fingerprint) {
                    otrl_privkey_hash_to_human(their_hash, fingerprint->fingerprint);
                    msg = [NSString stringWithFormat:@"Fingerprint for you, %s:\n%s\n\nPurported fingerprint for %s:\n%s\n", context->accountname, our_hash, context->username, their_hash];
                } else {
                    msg = @"You must be in a secure conversation first.";
                }
                                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Verify Fingerprint" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
            }
        }
        else if (buttonIndex == 0)
        {
            OTRBuddy* theBuddy = buddy;
            OTRMessage *newMessage = [OTRMessage messageWithSender:[self.protocolManager accountNameForProtocol:buddy.protocol] recipient:theBuddy.accountName message:@"" protocol:buddy.protocol];
            OTRMessage *encodedMessage = [OTRCodec encodeMessage:newMessage];
            [OTRMessage sendMessage:encodedMessage];    
        }
        else if (buttonIndex == actionSheet.cancelButtonIndex) // Cancel
        {
            
        }
    }
    else
    {
        if (buttonIndex != actionSheet.cancelButtonIndex)
        {
            [[UIApplication sharedApplication] openURL:[lastActionLink absoluteURL]];
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
			UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:[[button.url absoluteURL] description] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", nil];
			[action showFromTabBar:self.tabBarController.tabBar];
		}
	}
}

-(void)viewWillAppear:(BOOL)animated
{
    [self refreshContext];
    [self refreshLockButton];
}

/*- (void)debugButton:(UIBarButtonItem *)sender
{
	_textView.contentView.drawDebugFrames = !_textView.contentView.drawDebugFrames;
	[DTCoreTextLayoutFrame setShouldDrawDebugFrames:_textView.contentView.drawDebugFrames];
	[self.view setNeedsDisplay];
}*/


//detailedView delegate methods
- (void)splitViewController:(UISplitViewController*)svc 
     willHideViewController:(UIViewController *)aViewController 
          withBarButtonItem:(UIBarButtonItem*)barButtonItem 
       forPopoverController:(UIPopoverController*)pc
{  
    [barButtonItem setTitle:@"Buddy List"];
    
    
    
    self.navigationItem.leftBarButtonItem = barButtonItem;
}


- (void)splitViewController:(UISplitViewController*)svc 
     willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}


@end
