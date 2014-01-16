//
//  OTRBuddyCell.h
//  Off the Record
//
//  Created by David Chiles on 12/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRManagedBuddy;

@interface OTRBuddyCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithBuddy:(OTRManagedBuddy *)buddy reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic,weak) OTRManagedBuddy * buddy;

@property (nonatomic) BOOL showStatus;

@end
