//
//  UITableView+ChatSecure.h
//  ChatSecure
//
//  Created by Chris Ballinger on 4/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@import UIKit;
@import YapDatabase;
#import "OTRThreadOwner.h"

NS_ASSUME_NONNULL_BEGIN
@interface UITableView (ChatSecure)

/** deleteActionAlsoRemovesFromRoster is YES for the ChooseBuddy view, otherwise NO. Connection must be read-write */
+ (nullable UISwipeActionsConfiguration *)editActionsForThread:(id<OTRThreadOwner>)thread deleteActionAlsoRemovesFromRoster:(BOOL)deleteActionAlsoRemovesFromRoster connection:(YapDatabaseConnection*)connection;

@end
NS_ASSUME_NONNULL_END
