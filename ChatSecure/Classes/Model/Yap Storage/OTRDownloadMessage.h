//
//  OTRDownloadMessage.h
//  ChatSecure
//
//  Created by Chris Ballinger on 5/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRBaseMessage.h"
#import "OTRIncomingMessage.h"

NS_ASSUME_NONNULL_BEGIN
// this class is intended to simplify downloading of media URLs
// that are contained within incoming messages
@interface OTRDownloadMessage : OTRBaseMessage <YapDatabaseRelationshipNode>

@property (nonatomic, strong, readonly) NSString *parentMessageId;
@property (nonatomic, strong, readonly) NSURL *url;

/** Returns an unsaved array of downloadable URLs. */
+ (NSArray<OTRDownloadMessage*>*) downloadsForMessage:(OTRBaseMessage*)message;

/**  If available, existing instances will be returned. */
+ (NSArray<OTRDownloadMessage*>*) existingDownloadsForMessage:(OTRBaseMessage*)message transaction:(YapDatabaseReadTransaction*)transaction;

/** Checks if edge count > 0 */
+ (BOOL) hasExistingDownloadsForMessage:(OTRBaseMessage*)message transaction:(YapDatabaseReadTransaction*)transaction;

@end

@interface UIAlertAction (OTRDownloadMessage)

+ (NSArray<UIAlertAction*>*) actionsForDownloadMessage:(OTRDownloadMessage*)downloadMessage sourceView:(UIView*)sourceView viewController:(UIViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
