//
//  OTRAccount.h
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
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

#define kOTRAccountUsernameKey @"kOTRAccountUsernameKey"
#define kOTRAccountProtocolKey @"kOTRAccountProtocolKey"
#define kOTRAccountRememberPasswordKey @"kOTRAccountRememberPasswordKey"

#define kAIMImageName @"aim.png"
#define kGTalkImageName @"gtalk.png"
#define kFacebookImageName @"facebook.png"
#define kXMPPImageName @"xmpp.png"

@interface OTRAccount : NSObject

@property (nonatomic, retain) NSString *username; // 
@property (nonatomic, retain) NSString *protocol; // kOTRProtocolType, defined in OTRProtocolManager.h
@property (nonatomic, retain) NSString *password; // nil if rememberPassword = NO, not stored in memory
@property (nonatomic, retain, readonly) NSString *uniqueIdentifier;
@property (nonatomic) BOOL rememberPassword;
@property (nonatomic) BOOL isConnected;

- (id) initWithProtocol:(NSString*)newProtocol;
- (id) initWithSettingsDictionary:(NSDictionary*)dictionary uniqueIdentifier:(NSString*)uniqueID;
- (void) save;
- (Class)protocolClass;
- (NSString *) providerName;
- (NSString *) imageName;
- (NSMutableDictionary*) accountDictionary;

@end
