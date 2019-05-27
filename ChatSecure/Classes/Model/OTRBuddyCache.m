//
//  OTRBuddyCache.m
//  ChatSecure
//
//  Created by Chris Ballinger on 12/8/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyCache.h"
#import "OTRDatabaseManager.h"
#import "OTRYapDatabaseObject.h"
#import "ChatSecureCoreCompat-Swift.h"

@implementation OTRXMPPRoomRuntimeProperties
- (instancetype)init {
    if (self = [super init]) {
        _onlineJids = [NSMutableArray array];
    }
    return self;
}
@end

@interface OTRBuddyCache() {
    void *IsOnInternalQueueKey;
}
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSNumber*> *chatStates;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSNumber*> *lastSentChatStates;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSString*> *statusMessages;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSDictionary<NSString*, NSNumber*>*> *threadStatuses;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSNumber*> *waitingForvCardTempFetch;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,NSDate*> *lastSeenDates;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*,OTRXMPPRoomRuntimeProperties*> *roomProperties;

@property (nonatomic, strong, readonly) dispatch_queue_t queue;

/** Uses dispatch_barrier_async. Will perform block asynchronously on the internalQueue, unless we're already on internalQueue */
- (void) performAsyncWrite:(dispatch_block_t)block;

/** Uses dispatch_sync. Will perform block synchronously on the internalQueue and block for result if called on another queue. */
- (void) performSyncRead:(dispatch_block_t)block;

@end

@implementation OTRBuddyCache

- (instancetype) init {
    if (self = [super init]) {
        // We use dispatch_barrier_async with a concurrent queue to allow for multiple-read single-write.
        _queue = dispatch_queue_create("OTRBuddyCache", DISPATCH_QUEUE_CONCURRENT);
        
        // For safe usage of dispatch_sync
        IsOnInternalQueueKey = &IsOnInternalQueueKey;
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(_queue, IsOnInternalQueueKey, nonNullUnusedPointer, NULL);
        
        _chatStates = [NSMutableDictionary dictionary];
        _lastSentChatStates = [NSMutableDictionary dictionary];
        _statusMessages = [NSMutableDictionary dictionary];
        _threadStatuses = [NSMutableDictionary dictionary];
        _waitingForvCardTempFetch = [NSMutableDictionary dictionary];
        _lastSeenDates = [NSMutableDictionary dictionary];
        _roomProperties = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (OTRBuddyCache*)shared
{
    static OTRBuddyCache* sharedInstance = nil;
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
    
    [self performAsyncWrite:^{
        [self.chatStates setObject:@(chatState) forKey:buddy.uniqueId];
        [self touchBuddy:buddy];
    }];
}

- (OTRChatState) chatStateForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return OTRChatStateUnknown; }
    
    __block OTRChatState chatState = OTRChatStateUnknown;
    [self performSyncRead:^{
        chatState = [self.chatStates objectForKey:buddy.uniqueId].unsignedIntegerValue;
    }];
    return chatState;
}

- (void) setLastSentChatState:(OTRChatState)lastSentChatState forBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    
    [self performAsyncWrite:^{
        [self.lastSentChatStates setObject:@(lastSentChatState) forKey:buddy.uniqueId];
        [self touchBuddy:buddy];
    }];
}

- (OTRChatState) lastSentChatStateForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return OTRChatStateUnknown; }
    
    __block OTRChatState lastSentChatState = OTRChatStateUnknown;
    [self performSyncRead:^{
        lastSentChatState = [self.lastSentChatStates objectForKey:buddy.uniqueId].unsignedIntegerValue;
    }];
    return lastSentChatState;
}

- (void) setStatusMessage:(nullable NSString*)statusMessage forBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    
    [self performAsyncWrite:^{
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
    [self performSyncRead:^{
        statusMessage = [self.statusMessages objectForKey:buddy.uniqueId];
    }];
    return statusMessage;
}

- (void)setThreadStatus:(OTRThreadStatus)status forBuddy:(OTRBuddy*)buddy resource:(NSString *)_resource {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    [self performAsyncWrite:^{
        NSString *resource = [_resource copy];
        if (!resource) {
            [self.threadStatuses removeObjectForKey:buddy.uniqueId];
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

    [self performSyncRead:^{
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

- (void)setWaitingForvCardTempFetch:(BOOL)waiting forVcard:(id<OTRvCard>)vCard {
    NSParameterAssert(vCard.uniqueId);
    if (!vCard.uniqueId) { return; }
    [self performAsyncWrite:^{
        [self.waitingForvCardTempFetch setObject:@(waiting) forKey:vCard.uniqueId];
        [self touchObject:vCard];
    }];
}

- (BOOL)waitingForvCardTempFetchForVcard:(id<OTRvCard>)vCard {
    NSParameterAssert(vCard.uniqueId);
    if (!vCard.uniqueId) { return NO; }
    __block BOOL waiting = NO;
    [self performSyncRead:^{
        waiting = [self.waitingForvCardTempFetch objectForKey:vCard.uniqueId].boolValue;
    }];
    return waiting;
}

/**
 * Last Seen is associated with querying a presence with delayed delivery. See https://xmpp.org/extensions/xep-0318.html
 */
- (nullable NSDate*) lastSeenDateForBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return nil; }
    __block NSDate *date = nil;
    [self performSyncRead:^{
        date = [self.lastSeenDates objectForKey:buddy.uniqueId];
    }];
    return date;
}

- (void) setLastSeenDate:(nullable NSDate*)date forBuddy:(OTRBuddy*)buddy {
    NSParameterAssert(buddy.uniqueId);
    if (!buddy.uniqueId) { return; }
    [self performAsyncWrite:^{
        if (date) {
            [self.lastSeenDates setObject:date forKey:buddy.uniqueId];
        } else {
            [self.lastSeenDates removeObjectForKey:buddy.uniqueId];
        }
        [self touchBuddy:buddy];
    }];
}

- (OTRXMPPRoomRuntimeProperties *)runtimePropertiesForRoom:(OTRXMPPRoom *)room {
    NSParameterAssert(room.uniqueId);
    if (!room.uniqueId) { return nil; }
    __block OTRXMPPRoomRuntimeProperties *properties = nil;
    [self performSyncRead:^{
        properties = [self.roomProperties objectForKey:room.uniqueId];
        if (!properties) {
            properties = [[OTRXMPPRoomRuntimeProperties alloc] init];
            [self performAsyncWrite:^{
                [self.roomProperties setObject:properties forKey:room.uniqueId];
            }];
        }
    }];
    return properties;
}

- (void)setJid:(NSString *)jid online:(BOOL)online inRoom:(OTRXMPPRoom *)room {
    OTRXMPPRoomRuntimeProperties *properties = [self runtimePropertiesForRoom:room];
    if (properties) {
        if (online) {
            if (![properties.onlineJids containsObject:jid]) {
                [properties.onlineJids addObject:jid];
            }
        } else {
            if ([properties.onlineJids containsObject:jid]) {
                [properties.onlineJids removeObject:jid];
            }
        }
    }
}

- (BOOL)jidOnline:(NSString *)jid inRoom:(OTRXMPPRoom *)room {
    OTRXMPPRoomRuntimeProperties *properties = [self runtimePropertiesForRoom:room];
    return (properties && [properties.onlineJids containsObject:jid]);
}


/** Clears everything for given buddies */
- (void) purgeAllPropertiesForBuddies:(NSArray <OTRBuddy*>*)buddies {
    
    if([buddies count] == 0) {
        return;
    }
    
    [self performAsyncWrite:^{
        [buddies enumerateObjectsUsingBlock:^(OTRBuddy * _Nonnull buddy, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.chatStates removeObjectForKey:buddy.uniqueId];
            [self.lastSentChatStates removeObjectForKey:buddy.uniqueId];
            [self.statusMessages removeObjectForKey:buddy.uniqueId];
            [self.threadStatuses removeObjectForKey:buddy.uniqueId];
            [self.waitingForvCardTempFetch removeObjectForKey:buddy.uniqueId];
        }];
    }];
    
    [self performAsyncWrite:^{
        [[OTRDatabaseManager sharedInstance].writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [buddies enumerateObjectsUsingBlock:^(OTRBuddy * _Nonnull buddy, NSUInteger idx, BOOL * _Nonnull stop) {
                [self touchBuddy:buddy withTransaction:transaction];
            }];
        }];
    }];
}

/** Clears everything for given rooms */
- (void) purgeAllPropertiesForRooms:(NSArray <OTRXMPPRoom*>*)rooms {
    
    if([rooms count] == 0) {
        return;
    }
    
    [self performAsyncWrite:^{
        [rooms enumerateObjectsUsingBlock:^(OTRXMPPRoom * _Nonnull room, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.roomProperties removeObjectForKey:room.uniqueId];
        }];
    }];
}

#pragma mark Utility

/** This is needed so database views are updated properly */
- (void) touchBuddy:(OTRBuddy*)buddy withTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    [self touchObject:buddy withTransaction:transaction];
}

- (void) touchBuddy:(OTRBuddy*)buddy {
    [self touchObject:buddy];
}

- (void) touchObject:(id<OTRYapDatabaseObjectProtocol>)object withTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    NSParameterAssert(object.uniqueId != nil);
    if (!object.uniqueId) { return; }
    [transaction touchObjectForKey:object.uniqueId inCollection:object.yapCollection];
}

- (void) touchObject:(id<OTRYapDatabaseObjectProtocol>)object {
    [OTRDatabaseManager.shared.writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [self touchObject:object withTransaction:transaction];
    }];
}


/** Will perform block synchronously on the internalQueue and block for result if called on another queue. */
- (void) performSyncRead:(dispatch_block_t)block {
    NSParameterAssert(block != nil);
    if (!block) { return; }
    if (dispatch_get_specific(IsOnInternalQueueKey)) {
        block();
    } else {
        dispatch_sync(_queue, block);
    }
}

/** Will perform block asynchronously on the internalQueue, unless we're already on internalQueue */
- (void) performAsyncWrite:(dispatch_block_t)block {
    NSParameterAssert(block != nil);
    if (!block) { return; }
    if (dispatch_get_specific(IsOnInternalQueueKey)) {
        block();
    } else {
        dispatch_barrier_async(_queue, block);
    }
}

@end
