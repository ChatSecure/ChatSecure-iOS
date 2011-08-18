//
//  OTRChatViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRChatViewController.h"


@implementation OTRChatViewController
@synthesize chatHistoryTextView;
@synthesize messageTextField;
@synthesize buddyListController;


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
    NSString *newMessage = [buddyListController.messageCodec encodeMessage:message toUser:self.title];
    
    AIMSessionManager *theSession = [OTRBuddyListViewController AIMSession];
    AIMMessage * msg = [AIMMessage messageWithBuddy:[theSession.session.buddyList buddyWithUsername:self.title] message:newMessage];
	[theSession.messageHandler sendMessage:msg];
    
}

-(void)receiveMessage:(NSString *)message
{
    
    chatHistoryTextView.text = [chatHistoryTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n%@: %@",self.title,message]];
    [self scrollTextView:chatHistoryTextView];

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
