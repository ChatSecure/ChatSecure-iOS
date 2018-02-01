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

- (void)setWaitingForvCardTempFetch:(BOOL)waiting forBuddy:(OTRXMPPBuddy*)buddy;
- (BOOL)waitingForvCardTempFetchForBuddy:(OTRXMPPBuddy*)buddy;

/** 
 * Last Seen is associated with querying a presence with delayed delivery. See https://xmpp.org/extensions/xep-0318.html
 */
- (nullable NSDate*) lastSeenDateForBuddy:(OTRBuddy*)buddy;
- (void) setLastSeenDate:(nullable NSDate*)date forBuddy:(OTRBuddy*)buddy;

/**
 Room status
 */
- (void) setJoined:(BOOL)joined forRoom:(OTRXMPPRoom*)room;
- (BOOL) joinedForRoom:(OTRXMPPRoom*)room;

/**
 Flag that indicates if we have fetched initial history for the room upon joining
 */
- (void) setHasFetchedHistory:(BOOL)hasFetchedHistory forRoom:(OTRXMPPRoom*)room;
- (BOOL) hasFetchedHistoryForRoom:(OTRXMPPRoom*)room;

@end
NS_ASSUME_NONNULL_END
