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

@interface OTRProtocolManager : NSObject
{
    
}

@property (nonatomic, retain) OTRBuddyList *buddyList;

@property (nonatomic, retain) OTROscarManager *oscarManager;
@property (nonatomic, retain) OTRXMPPManager *xmppManager;
@property (nonatomic, retain) OTREncryptionManager *encryptionManager;

+ (OTRProtocolManager*)sharedInstance; // Singleton method

-(void)sendMessage:(NSNotification*)notification;
-(NSArray*)frcSections;

-(void)sendMessageOSCAR:(OTRMessage*)theMessage;
-(void)sendMessageXMPP:(OTRMessage*)theMessage;

-(void)buddyListUpdate;

-(NSString*)accountNameForProtocol:(NSString*)protocol;


@end
