//
//  OTRYapMessageSendAction.m
//  ChatSecure
//
//  Created by David Chiles on 5/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRYapMessageSendAction.h"
#import "OTRBuddy.h"
#import "ChatSecureCoreCompat-Swift.h"

@interface OTRYapMessageSendAction()
@property (nonatomic, strong, nonnull) NSString *buddyKey DEPRECATED_MSG_ATTRIBUTE("Deprecated in favor of threadKey");
@end

@implementation OTRYapMessageSendAction
// Why is auto property synthesis not working? Come on Xcode 9 beta...
@synthesize threadKey = _threadKey;
@synthesize threadCollection = _threadCollection;

- (nonnull instancetype)initWithMessageKey:(nonnull NSString *)messageKey
                         messageCollection:(nonnull NSString *)messageCollection
                                 threadKey:(nonnull NSString *)threadKey
                          threadCollection:(nonnull NSString*)threadCollection
                                      date:(nonnull NSDate *)date {
    if (self = [self init]) {
        _messageKey = [messageKey copy];
        _messageCollection = [messageCollection copy];
        _threadKey = [threadKey copy];
        _threadCollection = [threadCollection copy];
        _date = date;
    }
    return self;
}

- (NSString*) threadKey {
    // Legacy fallback
    if (!_threadKey) {
        _threadKey = _buddyKey;
    }
    return _threadKey;
}

- (NSString*) threadCollection {
    // Legacy fallback
    if (!_threadCollection) {
        _threadCollection = [OTRBuddy collection];
    }
    return _threadCollection;
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
+ (instancetype)sendActionForMessage:(id<OTRMessageProtocol>)message date:(nullable NSDate *)date {
    NSParameterAssert(message != nil);
    if (!date) {
        date = NSDate.date;
    }
    OTRYapMessageSendAction *sendingAction = [[OTRYapMessageSendAction alloc] initWithMessageKey:message.messageKey messageCollection:message.messageCollection threadKey:message.threadId threadCollection:message.threadCollection date:date];
    return sendingAction;
}

// MARK: YapTaskQueueAction

- (NSString*) yapKey {
    return self.uniqueId;
}

- (NSString*) yapCollection {
    return [self.class collection];
}

- (NSString*) queueName {
    NSString *brokerName = [YapDatabaseConstants extensionName:DatabaseExtensionNameMessageQueueBrokerViewName];
    NSString *queueName = [NSString stringWithFormat:@"%@.%@", brokerName, self.threadKey];
    return queueName;
}

- (NSComparisonResult) sort:(id<YapTaskQueueAction>)otherObject {
    id anyOther = otherObject; // Can't check class on id<YapTaskQueueAction>
    if ([anyOther isKindOfClass:OTRYapMessageSendAction.class]) {
        OTRYapMessageSendAction *other = (OTRYapMessageSendAction*)anyOther;
        NSDate *otherDate = other.date;
        return [self.date compare:otherDate];
    } else {
        return NSOrderedSame;
    }
}

@end
