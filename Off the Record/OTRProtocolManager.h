//
//  OTRProtocolManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTROscarManager.h"
#import "OTRXMPPManager.h"
#import "OTREncryptionManager.h"
#import "OTRCodec.h"

@interface OTRProtocolManager : NSObject
{
    
}

@property (nonatomic, retain) OTROscarManager *oscarManager;
@property (nonatomic, retain) OTRXMPPManager *xmppManager;
@property (nonatomic, retain) OTREncryptionManager *encryptionManager;

+ (OTRProtocolManager*)sharedInstance; // Singleton method

-(void)sendMessage:(NSNotification*)notification;

-(void)sendMessageOSCAR:(NSDictionary*)messageInfo;
-(void)sendMessageXMPP:(NSDictionary*)messageInfo;

-(OTRCodec*)codecForProtocol:(NSString*)protocol;

@end
