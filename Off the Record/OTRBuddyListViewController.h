//
//  OTRBuddyListViewController.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LibOrange.h"
#import "CommandTokenizer.h"
#import "proto.h"

static     OtrlUserState s_OTR_userState;

@interface OTRBuddyListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, AIMLoginDelegate, AIMSessionManagerDelegate, AIMFeedbagHandlerDelegate, AIMICBMHandlerDelegate, AIMStatusHandlerDelegate, AIMRateLimitHandlerDelegate, AIMRendezvousHandlerDelegate, UIAlertViewDelegate> {
    
    AIMLogin * login;
	AIMSessionManager * theSession;
	NSThread * mainThread;
    
    UITableView *buddyListTableView;
    
    AIMBlist *buddyList;
    
    NSMutableDictionary *chatViewControllers;
    
    UIViewController *loginController;
    
    NSString *accountName;
}

@property (nonatomic, retain) IBOutlet UITableView *buddyListTableView;
@property (nonatomic, retain) AIMSessionManager * theSession;
@property (nonatomic, retain) AIMLogin * login;
@property (nonatomic, retain)     NSString *accountName;


-(void)enterConversation:(NSString*)buddyName;
+(OtrlUserState) OTR_userState;


//test
- (void)blockingCheck;
- (void)checkThreading;

- (NSString *)removeBuddy:(NSString *)username;
- (NSString *)addBuddy:(NSString *)username toGroup:(NSString *)groupName;
- (NSString *)deleteGroup:(NSString *)groupName;
- (NSString *)addGroup:(NSString *)groupName;
- (NSString *)denyUser:(NSString *)username;
- (NSString *)undenyUser:(NSString *)username;
//end test

@end
