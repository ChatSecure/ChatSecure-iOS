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
        self.messsageKey = messageKey;
        self.messageCollection = messageCollection;
        self.buddyKey = buddyKey;
        self.date = date;
    }
    return self;
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
