//
//  OTRYapMessageSendAction.m
//  ChatSecure
//
//  Created by David Chiles on 5/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRYapMessageSendAction.h"

@implementation OTRYapMessageSendAction

- (instancetype)initWithMessageKey:(NSString *)messageKey messageCollection:(NSString *)messageCollection buddyKey:(NSString *)buddyKey date:(NSDate *)date {
    if (self = [self init]) {
        self.messageKey = messageKey;
        self.messageCollection = messageCollection;
        self.buddyKey = buddyKey;
        self.date = date;
    }
    return self;
}

- (NSString *)uniqueId {
    return [[self class] actionKeyForMessageKey:self.messageKey messageCollection:self.messageCollection];
}

//MARK: Class Methods

+ (nonnull NSString *)actionKeyForMessageKey:(nonnull NSString *)messageKey messageCollection:(nonnull NSString *)messageCollection
{
    return [NSString stringWithFormat:@"%@%@",messageKey,messageCollection];
}

/** Generates an action that will send specified message. Unsaved! Message must be saved for operation to succeed! */
+ (instancetype)sendActionForMessage:(OTROutgoingMessage*)message {
    NSParameterAssert(message);
    OTRYapMessageSendAction *sendingAction = [[OTRYapMessageSendAction alloc] initWithMessageKey:message.uniqueId messageCollection:[[message class] collection] buddyKey:message.threadId date:message.date];
    return sendingAction;
}

@end
