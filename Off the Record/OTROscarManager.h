//
//  OTROscarManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRCodec.h"
#import "LibOrange.h"
#import "CommandTokenizer.h"
#import "OTRProtocol.h"


//static 	   AIMSessionManager * s_AIMSession = nil;


@interface OTROscarManager : NSObject <AIMLoginDelegate, AIMSessionManagerDelegate, AIMFeedbagHandlerDelegate, AIMICBMHandlerDelegate, AIMStatusHandlerDelegate, AIMRateLimitHandlerDelegate, AIMRendezvousHandlerDelegate, OTRProtocol>
{
    AIMLogin * login;
    AIMBlist * aimBuddyList;
	NSThread * mainThread;
    AIMSessionManager *theSession;
}

@property (nonatomic, retain) AIMLogin * login;
@property (nonatomic, retain) AIMBlist * aimBuddyList;
@property (nonatomic, retain) AIMSessionManager *theSession;
@property (nonatomic, retain) NSString *accountName;
@property (nonatomic, assign) BOOL loginFailed;
@property (nonatomic) BOOL loggedIn;



//+(AIMSessionManager*) AIMSession;

- (void)blockingCheck;
- (void)checkThreading;

- (NSString *)removeBuddy:(NSString *)username;
- (NSString *)addBuddy:(NSString *)username toGroup:(NSString *)groupName;
- (NSString *)deleteGroup:(NSString *)groupName;
- (NSString *)addGroup:(NSString *)groupName;
- (NSString *)denyUser:(NSString *)username;
- (NSString *)undenyUser:(NSString *)username;


@end
