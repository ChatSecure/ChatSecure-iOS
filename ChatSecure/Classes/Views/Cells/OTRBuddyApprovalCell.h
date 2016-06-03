//
//  OTRBuddyApprovalCell.h
//  ChatSecure
//
//  Created by Chris Ballinger on 6/1/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyInfoCell.h"
@import BButton;

@interface OTRBuddyApprovalCell : OTRBuddyInfoCell

@property (nonatomic, strong) BButton *approveButton;
@property (nonatomic, strong) BButton *denyButton;
@property (nonatomic, copy) void (^actionBlock)(OTRBuddyApprovalCell *cell, BOOL approved);

@end
