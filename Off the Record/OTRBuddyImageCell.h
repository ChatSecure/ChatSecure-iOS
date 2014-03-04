//
//  OTRBuddyImageCell.h
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRManagedBuddy;

extern const CGFloat margin;

@interface OTRBuddyImageCell : UITableViewCell

@property (nonatomic, strong, readonly) UIImageView *avatarImageView;
@property (nonatomic, strong) UIColor *imageViewBorderColor;

- (void)setBuddy:(OTRManagedBuddy *)buddy;

+ (NSString *)reuseIdentifier;

@end
