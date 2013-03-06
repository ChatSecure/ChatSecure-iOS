//
//  OTRSubscriptionRequestsViewController.h
//  Off the Record
//
//  Created by David on 3/5/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRXMPPManagedPresenceSubscriptionRequest;

@interface OTRSubscriptionRequestsViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate>
{
    OTRXMPPManagedPresenceSubscriptionRequest * currentlySelectedRequest;
}


@property (nonatomic, strong) NSFetchedResultsController * subscriptionRequestsFetchedResultsController;

@end
