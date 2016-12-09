//
//  OTRBuddyCache.m
//  ChatSecure
//
//  Created by Chris Ballinger on 12/8/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyCache.h"
#import "OTRDatabaseManager.h"

@interface OTRBuddyCache() {
    void *IsOnInternalQueueKey;
}
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSNumber*> *chatStates;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSNumber*> *lastSentChatStates;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSString*> *statusMessages;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSDictionary<NSString*, NSNumber*>*> *threadStatuses;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSNumber*> *waitingForvCardTempFetch;

@property (nonatomic, strong, readonly) dispatch_queue_t queue;

/** Will perform block asynchronously on the internalQueue, unless we're already on internalQueue */
- (void) performBlockAsync:(dispatch_block_t)block;

/** Will perform block synchronously on the internalQueue and block for result if called on another queue. */
- (void) performBlock:(dispatch_block_t)block;

@end

@implementation OTRBuddyCache

- (instancetype) init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("OTRBuddyCache", 0);
        
        // For safe usage of dispatch_sync
        IsOnInternalQueueKey = &IsOnInternalQueueKey;
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(_queue, IsOnInternalQueueKey, nonNullUnusedPointer, NULL);
        
        _chatStates = [NSMutableDictionary dictionary];
        _lastSentChatStates = [NSMutableDictionary dictionary];
        _statusMessages = [NSMutableDictionary dictionary];
        _threadStatuses = [NSMutableDictionary dictionary];
        _waitingForvCardTempFetch = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark Setters/Getters

- (void) setChatState:(OTRChatState)chatState forBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    
    [self performBlockAsync:^{
        [self.chatStates setObject:@(chatState) forKey:buddy.uniqueId];
        [self touchBuddy:buddy];
    }];
}

- (OTRChatState) chatStateForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return OTRChatStateUnknown; }
    
    __block OTRChatState chatState = OTRChatStateUnknown;
    [self performBlock:^{
        chatState = [self.chatStates objectForKey:buddy.uniqueId].unsignedIntegerValue;
    }];
    return chatState;
}

- (void) setLastSentChatState:(OTRChatState)lastSentChatState forBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    
    [self performBlockAsync:^{
        [self.lastSentChatStates setObject:@(lastSentChatState) forKey:buddy.uniqueId];
        [self touchBuddy:buddy];
    }];
}

- (OTRChatState) lastSentChatStateForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return OTRChatStateUnknown; }
    
    __block OTRChatState lastSentChatState = OTRChatStateUnknown;
    [self performBlock:^{
        lastSentChatState = [self.lastSentChatStates objectForKey:buddy.uniqueId].unsignedIntegerValue;
    }];
    return lastSentChatState;
}

- (void) setStatusMessage:(nullable NSString*)statusMessage forBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    
    [self performBlockAsync:^{
        if (!statusMessage) {
            [self.statusMessages removeObjectForKey:buddy.uniqueId];
        } else {
            [self.statusMessages setObject:statusMessage forKey:buddy.uniqueId];
        }
        [self touchBuddy:buddy];
    }];
}

- (nullable NSString*) statusMessageForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return nil; }
    
    __block NSString *statusMessage = nil;
    [self performBlock:^{
        statusMessage = [self.statusMessages objectForKey:buddy.uniqueId];
    }];
    return statusMessage;
}

- (void)setThreadStatus:(OTRThreadStatus)status forBuddy:(OTRBuddy*)buddy {
    [self setThreadStatus:status forBuddy:buddy resource:nil];
}

- (void)setThreadStatus:(OTRThreadStatus)status forBuddy:(OTRBuddy*)buddy resource:(NSString *)_resource {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    [self performBlockAsync:^{
        NSString *resource = [_resource copy];
        if (!resource) {
            [self.threadStatuses removeAllObjects];
            resource = @"";
        }
        NSDictionary <NSString*,NSNumber*> *resourceInfo = @{resource: @(status)};
        [self.threadStatuses setObject:resourceInfo forKey:buddy.uniqueId];
        [self touchBuddy:buddy];
    }];
}

- (OTRThreadStatus)threadStatusForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return OTRThreadStatusOffline; }
    
    __block NSDictionary <NSString*,NSNumber*> *resourceInfo = nil;

    [self performBlock:^{
        resourceInfo = [self.threadStatuses objectForKey:buddy.uniqueId];
    }];
    
    if (!resourceInfo) {
        return OTRThreadStatusOffline;
    } else {
        __block OTRThreadStatus status = OTRThreadStatusOffline;
        [resourceInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            OTRThreadStatus resourceStatus = obj.intValue;
            // Check if it less than becauase OTRThreadStatusAvailable == 0 and the closer you are to OTRThreadStatusAvailable the more 'real' it is.
            if (resourceStatus < status) {
                status = resourceStatus;
            }
            
            if (status == OTRThreadStatusAvailable) {
                *stop = YES;
            }
            
        }];
        return status;
    }
}

- (void)setWaitingForvCardTempFetch:(BOOL)waiting forBuddy:(OTRXMPPBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    [self performBlockAsync:^{
        [self.waitingForvCardTempFetch setObject:@(waiting) forKey:buddy.uniqueId];
        [self touchBuddy:buddy];
    }];
}

- (BOOL)waitingForvCardTempFetchForBuddy:(OTRXMPPBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return NO; }
    __block BOOL waiting = NO;
    [self performBlock:^{
        waiting = [self.waitingForvCardTempFetch objectForKey:buddy.uniqueId].boolValue;
    }];
    return waiting;
}

/** Clears everything for a buddy */
- (void) purgeAllPropertiesForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    [self performBlockAsync:^{
        [self.chatStates removeObjectForKey:buddy.uniqueId];
        [self.lastSentChatStates removeObjectForKey:buddy.uniqueId];
        [self.statusMessages removeObjectForKey:buddy.uniqueId];
        [self.threadStatuses removeObjectForKey:buddy.uniqueId];
        [self.waitingForvCardTempFetch removeObjectForKey:buddy.uniqueId];
        [self touchBuddy:buddy];
    }];
}


#pragma mark Utility

/** This is needed so database views are updated properly */
- (void) touchBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction touchObjectForKey:buddy.uniqueId inCollection:[[buddy class] collection]];
    }];
}

/** Will perform block synchronously on the internalQueue and block for result if called on another queue. */
- (void) performBlock:(dispatch_block_t)block {
    NSParameterAssert(block != nil);
    if (!block) { return; }
    if (dispatch_get_specific(IsOnInternalQueueKey)) {
        block();
    } else {
        dispatch_sync(_queue, block);
    }
}

/** Will perform block asynchronously on the internalQueue, unless we're already on internalQueue */
- (void) performBlockAsync:(dispatch_block_t)block {
    NSParameterAssert(block != nil);
    if (!block) { return; }
    if (dispatch_get_specific(IsOnInternalQueueKey)) {
        block();
    } else {
        dispatch_async(_queue, block);
    }
}

@end
