//
//  OTRAccountTableViewCell.h
//  Off the Record
//
//  Created by David Chiles on 11/27/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import UIKit;
#import "OTRProtocol.h"

@class OTRAccount;

@interface OTRAccountTableViewCell : UITableViewCell

@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) OTRAccount *account;

- (void)setConnectedText:(OTRLoginStatus)connectionStatus;

+ (NSString*) cellIdentifier;

@end
