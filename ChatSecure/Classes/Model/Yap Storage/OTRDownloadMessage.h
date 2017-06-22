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
@interface OTRDownloadMessage : OTRBaseMessage <YapDatabaseRelationshipNode, OTRMessageChildProtocol>

@property (nonatomic, strong, readonly) NSString *parentMessageKey;
@property (nonatomic, strong, readonly) NSString *parentMessageCollection;
@property (nonatomic, strong, readonly) NSURL *url;

- (instancetype) initWithParentMessage:(id<OTRMessageProtocol>)parentMessage
                                   url:(NSURL*)url;

@end

@interface UIAlertAction (OTRDownloadMessage)

+ (NSArray<UIAlertAction*>*) actionsForMediaMessage:(id<OTRMessageProtocol>)mediaMessage sourceView:(UIView*)sourceView viewController:(UIViewController*)viewController;

@end

NS_ASSUME_NONNULL_END
