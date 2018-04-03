//
//  OTRYapMessageSendAction.h
//  ChatSecure
//
//  Created by David Chiles on 5/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//
#import "OTRYapDatabaseObject.h"
#import "OTROutgoingMessage.h"
@import YapTaskQueue; // debugger AST fail
@protocol YapTaskQueueAction;

/**
 * This class represents a send action. The way it works is at the same time or after a OTRMessage 
 * is created and saved create one of these objects that points to a message. Once the message is 
 * saved it will be picked up by the queue and and the message queue hander.
 *
 * Todo: add yap relationship edge so that it is deleted if the message is deleted.
 */
NS_ASSUME_NONNULL_BEGIN
@interface OTRYapMessageSendAction : OTRYapDatabaseObject <YapTaskQueueAction>

@property (nonatomic, strong, readonly) NSString *messageKey;
@property (nonatomic, strong, readonly) NSString *messageCollection;
@property (nonatomic, strong, readonly) NSString *threadKey;
/** May be nil for legacy model versions */
@property (nonatomic, strong, nullable, readonly) NSString *threadCollection;
@property (nonatomic, strong, readonly) NSDate *date;

- (instancetype)initWithMessageKey:(NSString *)messageKey
                 messageCollection:(NSString *)messageCollection
                         threadKey:(NSString *)threadKey
                  threadCollection:(NSString*)threadCollection
                              date:(NSDate *)date;

+ (NSString *)actionKeyForMessageKey:(NSString *)messageKey
                   messageCollection:(NSString *)messageCollection;

/** Generates an action that will send specified message. Unsaved! Message must be saved for operation to succeed! */
+ (instancetype)sendActionForMessage:(id<OTRMessageProtocol>)message date:(nullable NSDate*)date;

@end
NS_ASSUME_NONNULL_END
