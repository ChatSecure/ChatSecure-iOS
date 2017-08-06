//
//  OTRYapMessageSendAction.m
//  ChatSecure
//
//  Created by David Chiles on 5/27/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRYapMessageSendAction.h"
#import "OTRBuddy.h"

@interface OTRYapMessageSendAction()
@property (nonatomic, strong, nonnull) NSString *buddyKey DEPRECATED_MSG_ATTRIBUTE("Deprecated in favor of threadKey");
@end

@implementation OTRYapMessageSendAction

- (instancetype)initWithMessageKey:(NSString *)messageKey messageCollection:(NSString *)messageCollection buddyKey:(NSString *)buddyKey date:(NSDate *)date {
    return [self initWithMessageKey:messageKey messageCollection:messageCollection threadKey:buddyKey threadCollection:[OTRBuddy collection] date:date];
}

- (nonnull instancetype)initWithMessageKey:(nonnull NSString *)messageKey
                         messageCollection:(nonnull NSString *)messageCollection
                                 threadKey:(nonnull NSString *)threadKey
                          threadCollection:(nonnull NSString*)threadCollection
                                      date:(nonnull NSDate *)date {
    if (self = [self init]) {
        self.messageKey = [messageKey copy];
        self.messageCollection = [messageCollection copy];
        self.threadKey = [threadKey copy];
        self.threadCollection = [threadCollection copy];
        self.date = date;
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
+ (instancetype)sendActionForMessage:(id<OTRMessageProtocol>)message {
    NSParameterAssert(message != nil);
    OTRYapMessageSendAction *sendingAction = [[OTRYapMessageSendAction alloc] initWithMessageKey:message.messageKey messageCollection:message.messageCollection threadKey:message.threadId threadCollection:<#(nonnull NSString *)#> date:<#(nonnull NSDate *)#>];
    return sendingAction;
}

@end
