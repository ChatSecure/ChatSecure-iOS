//
//  OTROscarManager.h
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
