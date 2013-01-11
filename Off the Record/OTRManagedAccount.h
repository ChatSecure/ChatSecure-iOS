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

#define kOTRAccountUsernameKey @"kOTRAccountUsernameKey"
#define kOTRAccountProtocolKey @"kOTRAccountProtocolKey"
#define kOTRAccountRememberPasswordKey @"kOTRAccountRememberPasswordKey"

#define kAIMImageName @"aim.png"
#define kGTalkImageName @"gtalk.png"
#define kFacebookImageName @"facebook.png"
#define kXMPPImageName @"xmpp.png"


@interface OTRManagedAccount : NSManagedObject

@property (nonatomic) BOOL isConnected;
@property (nonatomic, retain) NSString * protocol;
@property (nonatomic, readonly) BOOL rememberPassword;
@property (nonatomic, retain) NSString *password; // nil if rememberPassword = NO, not stored in memory
@property (nonatomic, retain) NSString * uniqueIdentifier;
@property (nonatomic, retain, readonly) NSString * username;

@property (nonatomic, retain) NSSet *buddies;

- (void) save;
- (Class) protocolClass;
- (NSString *) providerName;
- (NSString *) imageName;

- (void) setDefaultsWithProtocol:(NSString*)newProtocol;
- (void) setNewUsername:(NSString *)newUsername;
- (void) setShouldRememberPassword:(BOOL)remember;

@end

@interface OTRManagedAccount (CoreDataGeneratedAccessors)

- (void)addBuddiesObject:(NSManagedObject *)value;
- (void)removeBuddiesObject:(NSManagedObject *)value;
- (void)addBuddies:(NSSet *)values;
- (void)removeBuddies:(NSSet *)values;

@end
