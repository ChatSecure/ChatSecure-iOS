//
//  OTRManagedAccount.h
//  Off the Record
//
//  Created by Christopher Ballinger on 1/10/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "_OTRManagedAccount.h"
#import "OTRManagedBuddy.h"

#define kOTRAccountUsernameKey @"kOTRAccountUsernameKey"
#define kOTRAccountProtocolKey @"kOTRAccountProtocolKey"
#define kOTRAccountRememberPasswordKey @"kOTRAccountRememberPasswordKey"

#define kAIMImageName @"aim.png"
#define kGTalkImageName @"gtalk.png"
#define kFacebookImageName @"facebook.png"
#define kXMPPImageName @"xmpp.png"


@interface OTRManagedAccount : _OTRManagedAccount


@property (nonatomic, retain) NSString *password; // nil if rememberPassword = NO, not stored in memory

- (void) save;
- (Class) protocolClass;
- (NSString *) providerName;
- (NSString *) imageName;

-(void)setNewUsername:(NSString *)newUsername;
- (void) setDefaultsWithProtocol:(NSString*)newProtocol;

-(void)setAllBuddiesStatuts:(OTRBuddyStatus)status;
-(void)deleteAllConversationsForAccount;

-(void)prepareBuddiesandMessagesForDeletion;


//Goes through all accounts checks if it's connected againgst ProtocolManager and adjusts buddy status
+(void)resetAccountsConnectionStatus;

@end

@interface OTRManagedAccount (CoreDataGeneratedAccessors)

- (void)addBuddiesObject:(NSManagedObject *)value;
- (void)removeBuddiesObject:(NSManagedObject *)value;
- (void)addBuddies:(NSSet *)values;
- (void)removeBuddies:(NSSet *)values;

@end
