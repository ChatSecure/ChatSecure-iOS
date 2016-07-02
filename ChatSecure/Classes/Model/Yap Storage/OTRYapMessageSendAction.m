//
//  OTRYapMessageSendAction.m
//  ChatSecure
//
//  Created by David Chiles on 5/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRYapMessageSendAction.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>
#import <ChatSecureCore/ChatSecureCore.h>

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

//MARK: YapTaskQueueAction

- (NSString *)yapKey {
    return self.uniqueId;
}

- (NSString *)yapCollection {
    return [[self class] collection];
}

- (NSString *)queueName {
    NSString *brokerName = [YapDatabaseConstants extensionName:DatabaseExtensionNameMessageQueueBrokerViewName];
    return  [NSString stringWithFormat:@"%@.%@",brokerName,self.buddyKey];
}

- (NSComparisonResult)sort:(id<YapTaskQueueAction>)otherObject {
    if ([((NSObject *)otherObject) isKindOfClass:[self class]]) {
        return [self.date compare:((OTRYapMessageSendAction*)otherObject).date];
    }
    return NSOrderedSame;
}

@end
