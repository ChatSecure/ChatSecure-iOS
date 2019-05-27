//
//  OTRNewBuddyViewController.h
//  Off the Record
//
//  Created by David on 3/4/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import UIKit;
@class OTRAccount;
@class OTRNewBuddyViewController;
@class OTRBuddy;

@protocol OTRNewBuddyViewControllerDelegate <NSObject>
@optional
- (bool)shouldDismissViewController:(OTRNewBuddyViewController *)viewController;
- (void)controller:(OTRNewBuddyViewController *)viewController didAddBuddy:(OTRBuddy *)buddy;
@end

@interface OTRNewBuddyViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong)OTRAccount * account;
@property (nonatomic, strong)UITextField * accountNameTextField;
@property (nonatomic, strong)UITextField * displayNameTextField;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, weak) id<OTRNewBuddyViewControllerDelegate> delegate;

-(id)initWithAccountId:(NSString *)accountId;
- (void)populateFromQRResult:(NSString *)result;

@end
