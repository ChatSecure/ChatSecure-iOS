//
//  OTRNewAccountViewController.h
//  Off the Record
//
//  Created by David Chiles on 7/12/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Strings.h"
#import "OTRAccount.h"

@interface OTRNewAccountViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSArray * accounts;
}

@end
