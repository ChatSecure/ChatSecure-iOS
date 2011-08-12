//
//  OTRChatViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRBuddyListViewController.h"

@interface OTRChatViewController : UIViewController <UITextFieldDelegate> {
    UITextView *chatHistoryTextView;
    UITextField *messageTextField;
    OTRBuddyListViewController *buddyListController;
}

@property (retain, nonatomic) IBOutlet UITextView *chatHistoryTextView;
@property (retain, nonatomic) IBOutlet UITextField *messageTextField;
@property (retain, nonatomic) OTRBuddyListViewController *buddyListController;

- (IBAction)sendButtonPressed:(id)sender;
- (void)receiveMessage:(NSString*)message;
- (void)sendMessage:(NSString*)message;

@end
