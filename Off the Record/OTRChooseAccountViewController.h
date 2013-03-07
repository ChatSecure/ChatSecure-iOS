//
//  OTRChooseAccountViewController.h
//  Off the Record
//
//  Created by David on 3/7/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTRChooseAccountViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
{
    UITableView * tableView;
}

@property (nonatomic, strong) NSFetchedResultsController * onlineAccountsFetchedResultsController;

@end
