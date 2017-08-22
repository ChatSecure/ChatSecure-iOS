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

/** Thread safe getters and setters for ephemeral in-memory storage of some buddy properties */
@interface OTRBuddyCache : NSObject

@property (class, nonatomic, readonly) OTRBuddyCache *shared;

/** 
 Clears everything for a buddy
 */
- (void) purgeAllPropertiesForBuddies:(NSArray <OTRBuddy*>*)buddies;

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

@end
NS_ASSUME_NONNULL_END
