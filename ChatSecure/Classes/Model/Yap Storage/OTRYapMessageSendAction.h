//
//  OTRYapMessageSendAction.h
//  ChatSecure
//
//  Created by David Chiles on 5/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//
#import "OTRYapDatabaseObject.h"
@import YapTaskQueue;

/**
 * This class represents a send action. The way it works is at the same time or after a OTRMessage 
 * is created and saved create one of these objects that points to a message. Once the message is 
 * saved it will be picked up by the queue and and the message queue hander.
 *
 * Todo: add yap relationship edge so that it is deleted if the message is deleted.
 */
@interface OTRYapMessageSendAction : OTRYapDatabaseObject <YapTaskQueueAction>

@property (nonatomic, strong, nonnull) NSString *messsageKey;
@property (nonatomic, strong, nonnull) NSString *messageCollection;
@property (nonatomic, strong, nonnull) NSString *buddyKey;
@property (nonatomic, strong, nonnull) NSDate *date;
@property (nonatomic) BOOL sendEncrypted;

- (nonnull instancetype)initWithMessageKey:(nonnull NSString *)messageKey messageCollection:(nonnull NSString *)messageCollection buddyKey:(nonnull NSString *)buddyKey date:(nonnull NSDate *)date sendEncrypted:(BOOL)sendEncrypted;

@end
