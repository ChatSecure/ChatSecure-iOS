//
//  OTRAccountTableViewCell.h
//  Off the Record
//
//  Created by David Chiles on 11/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRManagedAccount;

@interface OTRAccountTableViewCell : UITableViewCell


- (void)setAccount:(OTRManagedAccount *)account;
- (id)initWithAccount:(OTRManagedAccount *)account reuseIdentifier:(NSString *)identifier;


@end
