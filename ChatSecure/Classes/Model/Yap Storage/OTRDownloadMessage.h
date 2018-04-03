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

@protocol OTRDownloadMessage <OTRMessageProtocol, OTRMessageChildProtocol, OTRChildObjectProtocol, OTRYapDatabaseObjectProtocol>
/** This can occasionally be nil if bad things happen */
@property (nonatomic, strong, readonly, nullable) NSURL *url;
+ (id<OTRDownloadMessage>) downloadWithParentMessage:(id<OTRMessageProtocol>)parentMessage
                                   url:(NSURL*)url;
@end

// this class is intended to simplify downloading of media URLs
// that are contained within incoming messages
@interface OTRDirectDownloadMessage : OTRBaseMessage <YapDatabaseRelationshipNode, OTRDownloadMessage>

@end

@interface UIAlertAction (OTRDownloadMessage)

+ (NSArray<UIAlertAction*>*) actionsForMediaMessage:(id<OTRMessageProtocol>)mediaMessage sourceView:(UIView*)sourceView viewController:(UIViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
