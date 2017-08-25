//
//  OTRBuddyInfoCell.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyImageCell.h"
#import "OTRAccount.h"

NS_ASSUME_NONNULL_BEGIN

extern const CGFloat OTRBuddyInfoCellHeight;

@interface OTRBuddyInfoCell : OTRBuddyImageCell

@property (nonatomic, strong, readonly) UILabel *nameLabel;
@property (nonatomic, strong, readonly) UILabel *identifierLabel;
@property (nonatomic, strong, readonly) UILabel *accountLabel;

/** If user has more than one account, more information needs to be shown to distinguish contacts from each account. See OTRComposeViewController.shouldShowAccountLabel for more info. */
- (void)setThread:(id<OTRThreadOwner>)thread account:(nullable OTRAccount*)account;

@end
NS_ASSUME_NONNULL_END
