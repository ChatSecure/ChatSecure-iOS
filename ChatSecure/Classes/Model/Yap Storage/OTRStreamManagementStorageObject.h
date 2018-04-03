//
//  OTRStreamManagementStorageObject.h
//  ChatSecure
//
//  Created by David Chiles on 11/19/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN
@class XMPPStreamManagementOutgoingStanza;
@interface OTRStreamManagementStorageObject : OTRYapDatabaseObject

//Use account uniqueId as the actual unique for faster lookup

@property (nonatomic) uint32_t timeout;
@property (nonatomic) uint32_t lastHandledByClient;
@property (nonatomic) uint32_t lastHandledByServer;
@property (nonatomic, strong, nullable) NSDate *lastDisconnectDate;
@property (nonatomic, strong, nullable) NSString *resumptionId;
@property (nonatomic, strong, nullable) NSArray<XMPPStreamManagementOutgoingStanza*> *pendingOutgoingStanzasArray;

@end
NS_ASSUME_NONNULL_END
