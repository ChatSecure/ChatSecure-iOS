//
//  OTRYapMessageSendAction.h
//  ChatSecure
//
//  Created by David Chiles on 5/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//
#import "OTRYapDatabaseObject.h"
#import "OTROutgoingMessage.h"


/**
 * This class represents a send action. The way it works is at the same time or after a OTRMessage 
 * is created and saved create one of these objects that points to a message. Once the message is 
 * saved it will be picked up by the queue and and the message queue hander.
 *
 * Todo: add yap relationship edge so that it is deleted if the message is deleted.
 */
NS_ASSUME_NONNULL_BEGIN
@interface OTRYapMessageSendAction : OTRYapDatabaseObject

@property (nonatomic, strong, nonnull) NSString *messageKey;
@property (nonatomic, strong, nonnull) NSString *messageCollection;
@property (nonatomic, strong, nonnull) NSString *buddyKey;
@property (nonatomic, strong, nonnull) NSDate *date;

- (nonnull instancetype)initWithMessageKey:(nonnull NSString *)messageKey messageCollection:(nonnull NSString *)messageCollection buddyKey:(nonnull NSString *)buddyKey date:(nonnull NSDate *)date;

+ (nonnull NSString *)actionKeyForMessageKey:(nonnull NSString *)messageKey messageCollection:(nonnull NSString *)messageCollection;

/** Generates an action that will send specified message. Unsaved! Message must be saved for operation to succeed! */
+ (instancetype)sendActionForMessage:(OTROutgoingMessage*)message;

@end
NS_ASSUME_NONNULL_END
