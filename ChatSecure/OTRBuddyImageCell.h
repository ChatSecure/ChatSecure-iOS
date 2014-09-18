//
//  OTRBuddyImageCell.h
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy;

extern const CGFloat OTRBuddyImageCellPadding;

@interface OTRBuddyImageCell : UITableViewCell

@property (nonatomic, strong, readonly) UIImageView *avatarImageView;
@property (nonatomic, strong) UIColor *imageViewBorderColor;
@property (nonatomic, readonly) BOOL addedConstraints;

- (void)setBuddy:(OTRBuddy *)buddy;

+ (NSString *)reuseIdentifier;

@end
