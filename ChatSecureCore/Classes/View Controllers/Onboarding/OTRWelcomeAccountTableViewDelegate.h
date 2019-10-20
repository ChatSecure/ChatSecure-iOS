//
//  OTRWelcomeAccountTableViewDelegate.h
//  ChatSecure
//
//  Created by David Chiles on 5/7/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@class OTRWelcomeAccountInfo;

@import UIKit;

@interface OTRWelcomeAccountTableViewDelegate : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *welcomeAccountInfoArray;

@end
