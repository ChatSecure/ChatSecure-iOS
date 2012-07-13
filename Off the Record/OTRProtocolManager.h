//
//  OTRProtocolManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

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
