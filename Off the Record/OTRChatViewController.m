//
//  OTRChatViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRChatViewController.h"
#import "OTREncryptionManager.h"
#import <QuartzCore/QuartzCore.h>
#import "Strings.h"
#import "OTRDoubleSetting.h"
#import "OTRConstants.h"
#import "OTRAppDelegate.h"

#define kTabBarHeight 0
#define kSendButtonWidth 60
#define ACTIONSHEET_SAFARI_TAG 0
#define ACTIONSHEET_ENCRYPTION_OPTIONS_TAG 1


@interface OTRChatViewController(Private)
- (void) refreshView;
@end

@implementation OTRChatViewController
@synthesize chatHistoryTextView;
@synthesize messageTextField;
@synthesize buddyListController;
@synthesize chatBoxView;
@synthesize lockButton, unlockedButton;
@synthesize lastActionLink;
@synthesize sendButton;
@synthesize keyboardIsShown;
@synthesize buddy;
@synthesize instructionsLabel;
@synthesize keyboardListener;

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
    self.instructionsLabel = nil;
    self.keyboardListener = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        //set notification for when keyboard shows/hides
        self.title = CHAT_STRING;
    }
    return self;
}

- (CGFloat) chatBoxViewHeight {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 50.0;
    } else {
        return 44.0;
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
    
    keyboardIsShown = [keyboardListener isVisible];
}

- (void)keyboardWillShow:(NSNotification *)n
{
    // This is an ivar I'm using to ensure that we do not do the frame size adjustment on the UIScrollView if the keyboard is already shown.  This can happen if the user, after fixing editing a UITextField, scrolls the resized UIScrollView to another UITextField and attempts to edit the next UITextField.  If we were to resize the UIScrollView again, it would be disastrous.  NOTE: The keyboard notification will fire even when the keyboard is already shown.
    
        
    CGFloat keyboardHeight = [self keyboardHeightForNotification:n];


    
    // resize the scrollview
    CGRect chatHistoryFrame = self.chatHistoryTextView.frame;
    CGRect chatBoxViewFrame = self.chatBoxView.frame;
    // I'm also subtracting a constant kTabBarHeight because my UIScrollView was offset by the UITabBar so really only the portion of the keyboard that is leftover pass the UITabBar is obscuring my UIScrollView.
    CGFloat offsetHeight = (keyboardHeight - kTabBarHeight);
    chatHistoryFrame.size.height -= offsetHeight;
    chatBoxViewFrame.origin.y -= offsetHeight;
    
    if ([keyboardListener isVisible]) {
        self.chatHistoryTextView.frame = chatHistoryFrame;
        self.chatBoxView.frame = chatBoxViewFrame;
    }
    else {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        // The kKeyboardAnimationDuration I am using is 0.3
        [UIView setAnimationDuration:[self keyboardAnimationDurationForNotification:n]];
        self.chatHistoryTextView.frame = chatHistoryFrame;
        self.chatBoxView.frame = chatBoxViewFrame;
        [UIView commitAnimations];
    }
    
    
    [self scrollTextViewToBottom];
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
    if(buddy.encryptionStatus == kOTRKitMessageStateEncrypted)
    {
        self.navigationItem.rightBarButtonItem = lockButton;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = unlockedButton;
    }
}

-(void)lockButtonPressed
{
    NSString *encryptionString = INITIATE_ENCRYPTED_CHAT_STRING;
    if (buddy.encryptionStatus == kOTRKitMessageStateEncrypted) {
        encryptionString = CANCEL_ENCRYPTED_CHAT_STRING;
    }
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:encryptionString, VERIFY_STRING, CLEAR_CHAT_HISTORY_STRING, nil];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    popupQuery.tag = ACTIONSHEET_ENCRYPTION_OPTIONS_TAG;
    [popupQuery showInView:[OTR_APP_DELEGATE window]];
}



#pragma mark - View lifecycle

- (void) loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.chatBoxView = [[UIView alloc] init];
    
    self.messageTextField = [[UITextField alloc] init];
    messageTextField.borderStyle = UITextBorderStyleRoundedRect;
    messageTextField.delegate = self;

    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendButton setTitle:SEND_STRING forState:UIControlStateNormal];
    [sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    

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
    keyboardListener = [OTRUIKeyboardListener shared];
    keyboardIsShown = [keyboardListener isVisible];
    //make contentSize bigger than your scrollSize (you will need to figure out for your own use case)

    

    //self.chatHistoryTextView = [[DTAttributedTextView alloc] initWithFrame:CGRectZero];
    self.chatHistoryTextView = [[UIWebView alloc] initWithFrame:CGRectZero];
	//chatHistoryTextView.textDelegate = self;
    self.chatHistoryTextView.delegate = self;
	chatHistoryTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
	[self.view addSubview:chatHistoryTextView];
    

    messageTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:chatBoxView];
    [self.chatBoxView addSubview:messageTextField];
    [self.chatBoxView addSubview:sendButton];

	// Display string
	//chatHistoryTextView.contentView.edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
	//chatHistoryTextView.attributedString = string;
    [chatHistoryTextView loadHTMLString:@"" baseURL:[NSURL URLWithString:@"/"]];
    chatHistoryTextView.userInteractionEnabled = YES;
    
    
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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    keyboardIsShown = [keyboardListener isVisible];
    
    
}

- (void) showDisconnectionAlert:(NSNotification*)notification {
    NSMutableString *message = [NSMutableString stringWithFormat:DISCONNECTED_MESSAGE_STRING, buddy.protocol.account.username];
    if ([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect]) {
        [message appendFormat:@" %@", DISCONNECTION_WARNING_STRING];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DISCONNECTED_TITLE_STRING message:message delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles: nil];
    [alert show];
}

- (void) setBuddy:(OTRBuddy *)newBuddy {
    if(buddy) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTREncryptionStateNotification object:buddy];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MESSAGE_PROCESSED_NOTIFICATION object:buddy];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolDiconnect object:self.buddy.protocol];
    }
    
    buddy = newBuddy;
    self.title = newBuddy.displayName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encryptionStateChangeNotification:) name:kOTREncryptionStateNotification object:buddy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageProcessedNotification:) name:MESSAGE_PROCESSED_NOTIFICATION object:buddy];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showDisconnectionAlert:)
     name:kOTRProtocolDiconnect
     object:self.buddy.protocol];
    
    [self refreshLockButton];
    [self updateChatHistory];
    [self refreshView];
}
     
     
- (void) messageProcessedNotification:(NSNotification*)notification {
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
    [self refreshLockButton];
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
    if (buddy.chatHistory) {
        OTRDoubleSetting *fontSizeSetting = (OTRDoubleSetting*)[[OTRProtocolManager sharedInstance].settingsManager settingForOTRSettingKey:kOTRSettingKeyFontSize];
        NSString *htmlString = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">p{font-size:%@;font-family: geneva, arial, helvetica, sans-serif;}</style></head><body>%@</body></html>",fontSizeSetting.stringValue, buddy.chatHistory];
        [chatHistoryTextView loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"/"]];
    }
}


-(void)scrollTextViewToBottom
{
    
    if(![buddy.chatHistory isEqualToString:@""])
    {
        NSInteger height = [[chatHistoryTextView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] intValue];
        NSString* javascript = [NSString stringWithFormat:@"window.scrollBy(0, %d);", height];   
        [chatHistoryTextView stringByEvaluatingJavaScriptFromString:javascript];
    }
    
    
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"buttonIndex: %d",buttonIndex);
    if(actionSheet.tag == ACTIONSHEET_ENCRYPTION_OPTIONS_TAG)
    {
        if (buttonIndex == 1) // Verify
        {
            NSString *msg = nil;
            NSString *ourFingerprintString = [[OTRKit sharedInstance] fingerprintForAccountName:buddy.protocol.account.username protocol:buddy.protocol.account.protocol];
            NSString *theirFingerprintString = [[OTRKit sharedInstance] fingerprintForUsername:buddy.accountName accountName:buddy.protocol.account.username protocol:buddy.protocol.account.protocol];
            
            if(ourFingerprintString && theirFingerprintString) {
                msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, buddy.protocol.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, buddy.accountName, theirFingerprintString];
            } else {
                msg = SECURE_CONVERSATION_STRING;
            }
                            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
            [alert show];
        }
        else if (buttonIndex == 0) // Initiate/cancel encryption
        {
            if(buddy.encryptionStatus == kOTRKitMessageStateEncrypted)
            {
                [[OTRKit sharedInstance]disableEncryptionForUsername:buddy.accountName accountName:buddy.protocol.account.username protocol:buddy.protocol.account.protocol];
            } else {
                OTRBuddy* theBuddy = buddy;
                OTRMessage * newMessage = [OTRMessage messageWithBuddy:theBuddy message:@""];
                OTRMessage *encodedMessage = [OTRCodec encodeMessage:newMessage];
                [OTRMessage sendMessage:encodedMessage];
            }
        }
        else if (buttonIndex == 2) { // Clear Chat History
            buddy.chatHistory = [NSMutableString string];
            buddy.lastMessage = @"";
            [self updateChatHistory];
        }
        else if (buttonIndex == actionSheet.cancelButtonIndex) // Cancel
        {
            
        }
    }
    else if (actionSheet.tag == ACTIONSHEET_SAFARI_TAG)
    {
        if (buttonIndex != actionSheet.cancelButtonIndex)
        {
            [[UIApplication sharedApplication] openURL:[lastActionLink absoluteURL]];
        }
    }
}


- (void) refreshView {
    if (!buddy) {
        if (!instructionsLabel) {
            int labelWidth = 500;
            int labelHeight = 100;
            self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-labelWidth/2, self.view.frame.size.height/2-labelHeight/2, labelWidth, labelHeight)];
            instructionsLabel.text = CHAT_INSTRUCTIONS_LABEL_STRING;
            instructionsLabel.numberOfLines = 2;
            [self.view addSubview:instructionsLabel];
            self.navigationItem.rightBarButtonItem = nil;
        }
    } else {
        if (instructionsLabel) {
            [self.instructionsLabel removeFromSuperview];
            self.instructionsLabel = nil;
        }
        CGRect frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height-[self chatBoxViewHeight]);
        self.chatHistoryTextView.frame = frame;
        self.chatBoxView.frame = CGRectMake(0,frame.size.height, self.view.frame.size.width, [self chatBoxViewHeight]);
        self.chatHistoryTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.chatBoxView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        self.messageTextField.frame = CGRectMake(0, 0, self.view.frame.size.width-kSendButtonWidth, self.chatBoxView.frame.size.height);
        self.sendButton.frame = CGRectMake(self.messageTextField.frame.size.width, 0, kSendButtonWidth , self.chatBoxView.frame.size.height);
        
        [self refreshLockButton];
        
        if ([keyboardListener isVisible])
            [self keyboardWillShow:[self.keyboardListener lastNotification]];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [self refreshView];
    [self updateChatHistory];
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
    [barButtonItem setTitle:BUDDY_LIST_STRING];
    
    
    
    self.navigationItem.leftBarButtonItem = barButtonItem;
}


- (void)splitViewController:(UISplitViewController*)svc 
     willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem = nil;
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.absoluteString isEqualToString:@"file:///"]) {
        return YES;
    }
    if ([[UIApplication sharedApplication] canOpenURL:request.URL])
    {
        self.lastActionLink = request.URL;
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:[[request.URL absoluteURL] description] delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:OPEN_IN_SAFARI_STRING, nil];
        [action setTag:ACTIONSHEET_SAFARI_TAG];
        [action showInView:[OTR_APP_DELEGATE window]];
    }
    return NO;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSInteger height = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] intValue];
    NSString* javascript = [NSString stringWithFormat:@"window.scrollBy(0, %d);", height];   
    [webView stringByEvaluatingJavaScriptFromString:javascript];
}





@end
