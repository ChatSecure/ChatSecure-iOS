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

#define ALERTVIEW_NOT_VERIFIED_TAG 0
#define ALERTVIEW_VERIFIED_TAG 1


@interface OTRChatViewController(Private)
- (void) refreshView;
@end

@implementation OTRChatViewController
@synthesize messageTextField;
@synthesize buddyListController;
@synthesize chatBoxView;
@synthesize lockButton, unlockedButton,lockVerifiedButton;
@synthesize lastActionLink;
@synthesize sendButton;
@synthesize buddy;
@synthesize instructionsLabel;
@synthesize chatStateLabel;
@synthesize chatStateImage;
@synthesize pausedChatStateTimer, inactiveChatStateTimer;
@synthesize chatHistoryTableView;

- (void) dealloc {
    self.lastActionLink = nil;
    self.buddyListController = nil;
    self.buddy = nil;
    self.chatStateImage = nil;
    self.chatHistoryTableView = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.messageTextField = nil;
    self.lockButton = nil;
    self.unlockedButton = nil;
    self.chatBoxView = nil;
    self.sendButton = nil;
    self.instructionsLabel = nil;
    self.chatHistoryTableView = nil;
    _messagesFetchedResultsController = nil;
    _buddyFetchedResultsController = nil;
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
    
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonImage = [UIImage imageNamed:@"Lock_Locked_Verified.png"];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    buttonFrame = [button frame];
    buttonFrame.size.width = buttonImage.size.width;
    buttonFrame.size.height = buttonImage.size.height;
    [button setFrame:buttonFrame];
    [button addTarget:self action:@selector(lockButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    lockVerifiedButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    [self refreshLockButton];
}

-(void)refreshLockButton
{
    BOOL trusted = [[OTRKit sharedInstance] finerprintIsVerifiedForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
    if(buddy.encryptionStatus.intValue == kOTRKitMessageStateEncrypted && trusted)
    {
        self.navigationItem.rightBarButtonItem = lockVerifiedButton;
    }
    else if(buddy.encryptionStatus.intValue == kOTRKitMessageStateEncrypted)
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
    NSString * verifiedString = VERIFY_STRING;
    if (buddy.encryptionStatus.intValue == kOTRKitMessageStateEncrypted) {
        encryptionString = CANCEL_ENCRYPTED_CHAT_STRING;
    }
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:CANCEL_STRING destructiveButtonTitle:nil otherButtonTitles:encryptionString, verifiedString, CLEAR_CHAT_HISTORY_STRING, nil];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    popupQuery.tag = ACTIONSHEET_ENCRYPTION_OPTIONS_TAG;
    [OTR_APP_DELEGATE presentActionSheet:popupQuery inView:self.view];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideOrShow:) name:UIKeyboardWillShowNotification object:nil];
    
    self.chatHistoryTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.chatHistoryTableView.dataSource = self;
    self.chatHistoryTableView.delegate = self;
    self.chatHistoryTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.chatHistoryTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.chatHistoryTableView];
    

    messageTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.view addSubview:chatBoxView];
    [self.chatBoxView addSubview:messageTextField];
    [self.chatBoxView addSubview:sendButton];
    
    
    [self setupLockButton];
    
    
    
    //set notification for when a key is pressed.
    //turn off scrolling and set the font details.
    //chatBox.scrollEnabled = NO;
    //chatBox.font = [UIFont fontWithName:@"Helvetica" size:14];
}

-(void)keyboardWillHideOrShow:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect keyboardFrameForTextField = [self.chatBoxView.superview convertRect:keyboardFrame fromView:nil];
    CGRect newTextFieldFrame = self.chatBoxView.frame;
    
    newTextFieldFrame.origin.y = keyboardFrameForTextField.origin.y - newTextFieldFrame.size.height;
    
    CGRect keyboardFrameForTableView = [self.chatHistoryTableView.superview convertRect:keyboardFrame fromView:nil];
    CGRect newTableViewFrame = CGRectMake(0, 0, self.chatHistoryTableView.frame.size.width, keyboardFrameForTableView.origin.y-newTextFieldFrame.size.height);
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        self.chatHistoryTableView.frame = newTableViewFrame;
        self.chatBoxView.frame = newTextFieldFrame;
    } completion:nil];
    //[self scrollTextViewToBottom];
}

- (void) showDisconnectionAlert:(NSNotification*)notification {
    NSMutableString *message = [NSMutableString stringWithFormat:DISCONNECTED_MESSAGE_STRING, buddy.account.username];
    if ([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect]) {
        [message appendFormat:@" %@", DISCONNECTION_WARNING_STRING];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:DISCONNECTED_TITLE_STRING message:message delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles: nil];
    [alert show];
}

- (void) setBuddy:(OTRManagedBuddy *)newBuddy {
    if(buddy) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTREncryptionStateNotification object:buddy];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MESSAGE_PROCESSED_NOTIFICATION object:buddy];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolDiconnect object:nil];
    }
    [self saveCurrentMessageText];
    
    buddy = newBuddy;
    self.title = newBuddy.displayName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(encryptionStateChangeNotification:) name:kOTREncryptionStateNotification object:buddy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageProcessedNotification:) name:MESSAGE_PROCESSED_NOTIFICATION object:buddy];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showDisconnectionAlert:)
     name:kOTRProtocolDiconnect
     object:nil];
    _messagesFetchedResultsController = nil;
    _buddyFetchedResultsController = nil;
    
    [self refreshLockButton];
    [self refreshView];
    [self updateChatState:NO];
}


     
- (void) messageProcessedNotification:(NSNotification*)notification {
    [self updateChatState:YES];
}

-(BOOL)isComposingVisible
{
    if ([self.chatHistoryTableView numberOfRowsInSection:0] == [[self.messagesFetchedResultsController sections][0] numberOfObjects]) {
        return NO;
    }
    return YES;
}
-(NSIndexPath *)lastIndexPath
{
    return [NSIndexPath indexPathForRow:([self.chatHistoryTableView numberOfRowsInSection:0] - 1) inSection:0];
}


-(void)removeComposing
{
    [self.chatHistoryTableView beginUpdates];
    [self.chatHistoryTableView deleteRowsAtIndexPaths:@[[self lastIndexPath]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.chatHistoryTableView endUpdates];
    
}
-(void)addComposing
{
    NSIndexPath * lastIndexPath = [self lastIndexPath];
    NSInteger newLast = [lastIndexPath indexAtPosition:lastIndexPath.length-1]+1;
    lastIndexPath = [[lastIndexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:newLast];
    [self.chatHistoryTableView beginUpdates];
    [self.chatHistoryTableView insertRowsAtIndexPaths:@[lastIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.chatHistoryTableView endUpdates];
}

- (void)updateChatState:(BOOL)animated
{
    if(self.buddy.chatState.intValue == kOTRChatStateComposing)
    {
        if (![self isComposingVisible]) {
            [self addComposing];
        }
        
    }
    else if(self.buddy.chatState.intValue == kOTRChatStatePaused)
    {
        if (![self isComposingVisible]) {
            [self addComposing];
        }

        
    }
    else if(self.buddy.chatState.intValue == kOTRChatStateActive)
    {
        if ([self isComposingVisible]) {
            [self removeComposing];
        }

    }
    else if(self.buddy.chatState.intValue == kOTRChatStateInactive)
        chatStateLabel.text = CHAT_STATE_INACTVIE_STRING;
    else if(self.buddy.chatState.intValue == kOTRChatStateGone)
        chatStateLabel.text = CHAT_STATE_GONE_STRING;
    else
        chatStateImage.alpha = 0;
    
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSRange textFieldRange = NSMakeRange(0, [textField.text length]);
    
    [buddy sendComposingChatState];
    
    if (NSEqualRanges(range, textFieldRange) && [string length] == 0)
    {
        [buddy sendActiveChatState];
    }
    
    return YES;
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
    BOOL secure = buddy.encryptionStatus.intValue == kOTRKitMessageStateEncrypted;
    [buddy sendMessage:messageTextField.text secure:secure];
    messageTextField.text = @"";
    [self.pausedChatStateTimer invalidate];
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
            NSString *ourFingerprintString = [[OTRKit sharedInstance] fingerprintForAccountName:buddy.account.username protocol:buddy.account.protocol];
            NSString *theirFingerprintString = [[OTRKit sharedInstance] fingerprintForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
            BOOL trusted = [[OTRKit sharedInstance] finerprintIsVerifiedForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
            
            
            UIAlertView * alert;
            if(ourFingerprintString && theirFingerprintString) {
                msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, buddy.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, buddy.accountName, theirFingerprintString];
                if(trusted)
                {
                    alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg delegate:self cancelButtonTitle:VERIFIED_STRING otherButtonTitles:NOT_VERIFIED_STRING, nil];
                    alert.tag = ALERTVIEW_VERIFIED_TAG;
                }
                else
                {
                    alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg delegate:self cancelButtonTitle:VERIFY_LATER_STRING otherButtonTitles:VERIFIED_STRING, nil];
                    alert.tag = ALERTVIEW_NOT_VERIFIED_TAG;
                }
            } else {
                msg = SECURE_CONVERSATION_STRING;
               alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
            }
                            
            [alert show];
        }
        else if (buttonIndex == 0) // Initiate/cancel encryption
        {
            if(buddy.encryptionStatus.intValue == kOTRKitMessageStateEncrypted)
            {
                [[OTRKit sharedInstance]disableEncryptionForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol];
            } else {
                OTRManagedBuddy* theBuddy = buddy;
                OTRManagedMessage * newMessage = [OTRManagedMessage newMessageToBuddy:theBuddy message:@""];
                OTRManagedMessage *encodedMessage = [OTRCodec encodeMessage:newMessage];
                [OTRManagedMessage sendMessage:encodedMessage];
            }
        }
        else if (buttonIndex == 2) { // Clear Chat History
            [buddy removeMessages:buddy.messages];
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

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1 && alertView.tag == ALERTVIEW_NOT_VERIFIED_TAG)
    {
        [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:buddy.accountName accountName:buddy.account.username protocol:buddy.account.protocol verrified:YES];
        [self refreshLockButton];
    }
    else if(buttonIndex == 1 && alertView.tag == ALERTVIEW_VERIFIED_TAG)
    {
        [[OTRKit sharedInstance] changeVerifyFingerprintForUsername:buddy.accountName accountName:buddy.account.username  protocol:buddy.account.protocol verrified:NO];
        [self refreshLockButton];
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
        
        [self.chatHistoryTableView reloadData];
        [self.messageTextField resignFirstResponder];
        self.messageTextField.text = self.buddy.composingMessageString;
        if(![self.buddy.composingMessageString length])
        {
            [self.buddy sendActiveChatState];
        }
        CGRect frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height-[self chatBoxViewHeight]);
        self.chatHistoryTableView.frame = frame;
        self.chatBoxView.frame = CGRectMake(0,frame.size.height, self.view.frame.size.width, [self chatBoxViewHeight]);
        self.chatHistoryTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.chatBoxView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        self.messageTextField.frame = CGRectMake(0, 0, self.view.frame.size.width-kSendButtonWidth, self.chatBoxView.frame.size.height);
        self.sendButton.frame = CGRectMake(self.messageTextField.frame.size.width, 0, kSendButtonWidth , self.chatBoxView.frame.size.height);
        
        [self refreshLockButton];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [self refreshView];
    [self updateChatState:NO];
}

-(void)saveCurrentMessageText
{
    self.buddy.composingMessageString = self.messageTextField.text;
    if(![self.buddy.composingMessageString length])
    {
        [self.buddy sendInactiveChatState];
    }
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
        [OTR_APP_DELEGATE presentActionSheet:action inView:self.view];
    }
    return NO;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSInteger height = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] intValue];
    NSString* javascript = [NSString stringWithFormat:@"window.scrollBy(0, %d);", height];   
    [webView stringByEvaluatingJavaScriptFromString:javascript];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numMessages = [[self.messagesFetchedResultsController sections][section] numberOfObjects];
    if (buddy.chatStateValue == 2 || buddy.chatStateValue == 3) {
        numMessages +=1;
    }
    return numMessages;
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    

    if ((buddy.chatStateValue == 2 || buddy.chatStateValue == 3) && indexPath.row > [[self.messagesFetchedResultsController sections][indexPath.section] numberOfObjects]-1){
        cell.textLabel.text = @"Composing";
    }
    else {
        OTRManagedMessage *message = [self.messagesFetchedResultsController objectAtIndexPath:indexPath];
        
        cell.textLabel.text = message.message;
        cell.textLabel.textColor = [UIColor redColor];
        if (message.isIncoming) {
            cell.textLabel.textColor = [UIColor blueColor];
        }
    }
    
    return cell;
    
}

#pragma mark - NSFetchedResultsControllerDelegate

-(NSFetchedResultsController *)buddyFetchedResultsController{
    if (_buddyFetchedResultsController)
        return _buddyFetchedResultsController;
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"self == %@",self.buddy];
    NSPredicate * chatStateFilter = [NSPredicate predicateWithFormat:@"chatState == 2 OR chatState == 3"];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter,chatStateFilter]];
    
    _buddyFetchedResultsController = [OTRManagedBuddy MR_fetchAllGroupedBy:nil withPredicate:predicate sortedBy:nil ascending:YES delegate:nil];
    
    return _buddyFetchedResultsController;
}

- (NSFetchedResultsController *)messagesFetchedResultsController {
    if (_messagesFetchedResultsController)
        return _messagesFetchedResultsController;
    
    NSPredicate * buddyFilter = [NSPredicate predicateWithFormat:@"buddy == %@",self.buddy];
    NSPredicate * encryptionFilter = [NSPredicate predicateWithFormat:@"isEncrypted == NO"];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[buddyFilter, encryptionFilter]];
    
    _messagesFetchedResultsController = [OTRManagedMessage MR_fetchAllGroupedBy:nil withPredicate:predicate sortedBy:@"date" ascending:YES delegate:self];

    return _messagesFetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.chatHistoryTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.chatHistoryTableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.chatHistoryTableView endUpdates];
    //[self scrollToBottomAnimated:YES];
}



@end
