//
//  OTRProtocolManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
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
#import "OTROscarManager.h"
#import "OTRXMPPManager.h"
#import "OTREncryptionManager.h"
#import "OTRCodec.h"
#import "OTRBuddyList.h"
#import "OTRSettingsManager.h"
#import "OTRProtocol.h"
#import "OTRAccountsManager.h"

@interface OTRProtocolManager : NSObject

@property (nonatomic, retain) OTRBuddyList *buddyList;
@property (nonatomic, retain) OTREncryptionManager *encryptionManager;
@property (nonatomic, retain) OTRSettingsManager *settingsManager;
@property (nonatomic, retain) OTRAccountsManager *accountsManager;
@property (nonatomic, strong) NSMutableDictionary * protocolManagers;

+ (OTRProtocolManager*)sharedInstance; // Singleton method

-(void)sendMessage:(NSNotification*)notification;

-(void)buddyListUpdate;

-(OTRBuddy *)buddyForUserName:(NSString *)buddyUserName accountName:(NSString *)accountName protocol:(NSString *)protocol;

-(id <OTRProtocol>) protocolForAccount:(OTRAccount *)account;

@end
