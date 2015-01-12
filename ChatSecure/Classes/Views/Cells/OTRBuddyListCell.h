//
//  OTRBuddyInfoCell.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyImageCell.h"
#import "BFPaperCheckbox.h"

@interface OTRBuddyListCell : OTRBuddyImageCell

@property (nonatomic, strong, readonly) UILabel *nameLabel;
@property (nonatomic, strong, readonly) UILabel *identifierLabel;
@property (nonatomic, strong, readonly) UILabel *accountLabel;
@property (nonatomic, strong) BFPaperCheckbox *button;

- (void)setBuddy:(OTRBuddy *)buddy withAccountName:(NSString *)accountName;

@end
