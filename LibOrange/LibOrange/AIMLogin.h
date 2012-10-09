//
//  AIMLogin.h
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSessionManager.h"
#import "ANStringEscaper.h"
#import "ANCGIHTTPParameterReader.h"
#import "NSData+Base64.h"
#import "AIMLoginHostInfo.h"
#include "hmac-sha256.h"

#define kClientLoginURL @"https://api.screenname.aol.com/auth/clientLogin?f=http"
#define kStartOscarURL @"https://api.oscar.aol.com/aim/startOSCARSession"
#define kOSCARAPIKEY @"ma15d7JTxbmVG-RP" /* Key taken from libpurple source code. */

@class AIMLogin;

@protocol AIMLoginDelegate <NSObject>

@optional
- (void)aimLogin:(AIMLogin *)login failedWithError:(NSError *)error;
- (void)aimLogin:(AIMLogin *)login openedSession:(AIMSessionManager *)session;

@end

typedef enum {
	AIMLoginStageUnstarted = 0,
	AIMLoginStageSentFirst = 1,
	AIMLoginStageSentStart = 2
} AIMLoginStage;

@interface AIMLogin : NSObject <AIMSessionManagerDelegate> {
	id<AIMLoginDelegate> delegate;
	NSString * lusername, * lpassword;
	AIMLoginStage loginStage;
	AIMSessionManager * manager;
	
	/* HTTP Requests */
	NSURLConnection * currentRequest;
	NSMutableData * downloadedData;
	
	/* AIM request tokens */
	NSString * aToken;
	NSString * sessionKey;
	NSString * sessionSecret;
	NSString * hosttime;
}

@property (nonatomic, assign) id<AIMLoginDelegate> delegate;

- (id)initWithUsername:(NSString *)username password:(NSString *)password;
- (BOOL)beginAuthorization;

@end
