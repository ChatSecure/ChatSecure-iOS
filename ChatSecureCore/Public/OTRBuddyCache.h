//
//  OTRBuddyCache.h
//  ChatSecure
//
//  Created by Chris Ballinger on 12/8/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRXMPPBuddy.h"

NS_ASSUME_NONNULL_BEGIN

@class OTRXMPPRoom;
@class OTRXMPPRoomOccupant;

@interface OTRXMPPRoomRuntimeProperties : NSObject
@property (nonatomic) BOOL joined;
@property (nonatomic) BOOL hasFetchedHistory;
@property (nonatomic, strong) NSMutableArray *onlineJids;
@end

/** Thread safe getters and setters for ephemeral in-memory storage of some buddy properties */
@interface OTRBuddyCache : NSObject

@property (class, nonatomic, readonly) OTRBuddyCache *shared;

/** 
 Clears everything for given buddies
 */
- (void) purgeAllPropertiesForBuddies:(NSArray <OTRBuddy*>*)buddies;

/**
 Clears everything for given rooms
 */
- (void) purgeAllPropertiesForRooms:(NSArray <OTRXMPPRoom*>*)rooms;


- (void) setChatState:(OTRChatState)chatState forBuddy:(OTRBuddy*)buddy;
- (OTRChatState) chatStateForBuddy:(OTRBuddy*)buddy;

- (void) setLastSentChatState:(OTRChatState)lastSentChatState forBuddy:(OTRBuddy*)buddy;
- (OTRChatState) lastSentChatStateForBuddy:(OTRBuddy*)buddy;

- (void) setStatusMessage:(nullable NSString*)statusMessage forBuddy:(OTRBuddy*)buddy;
- (nullable NSString*) statusMessageForBuddy:(OTRBuddy*)buddy;

/** If resource is nil, it will clear out every other resource */
- (void)setThreadStatus:(OTRThreadStatus)status forBuddy:(OTRBuddy*)buddy resource:(nullable NSString *)resource;
- (OTRThreadStatus)threadStatusForBuddy:(OTRBuddy*)buddy;

- (void)setWaitingForvCardTempFetch:(BOOL)waiting forVcard:(id<OTRvCard>)vCard;
- (BOOL)waitingForvCardTempFetchForVcard:(id<OTRvCard>)vCard;

/** 
 * Last Seen is associated with querying a presence with delayed delivery. See https://xmpp.org/extensions/xep-0318.html
 */
- (nullable NSDate*) lastSeenDateForBuddy:(OTRBuddy*)buddy;
- (void) setLastSeenDate:(nullable NSDate*)date forBuddy:(OTRBuddy*)buddy;

/**
 Cached room properties
 */
- (nullable OTRXMPPRoomRuntimeProperties *) runtimePropertiesForRoom:(OTRXMPPRoom*)room;

- (void) setJid:(nonnull NSString*)jid online:(BOOL)online inRoom:(nonnull OTRXMPPRoom*)room;
- (BOOL) jidOnline:(NSString*)jid inRoom:(nonnull OTRXMPPRoom*)room;

@end
NS_ASSUME_NONNULL_END
