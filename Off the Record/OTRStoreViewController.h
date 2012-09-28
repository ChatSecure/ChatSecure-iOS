//
//  OTRStoreViewController.h
//  Off the Record
//
//  Created by Christopher Ballinger on 9/28/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTRStoreViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, retain) UITableView *productTableView;
@property (nonatomic, retain) NSArray *productIdentifiers;

@end
