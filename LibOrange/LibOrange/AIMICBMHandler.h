//
//  AIMICBMHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMMessage.h"
#import "AIMMissedCall.h"
#import "AIMICBMMessageToServer.h"

@class AIMICBMHandler;

@protocol AIMICBMHandlerDelegate <NSObject>

@optional
- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMessage:(AIMMessage *)message;
- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMissedCall:(AIMMissedCall *)missedCall;

@end

@interface AIMICBMHandler : NSObject <AIMSessionHandler> {
    AIMSession * session;
	id<AIMICBMHandlerDelegate> delegate;
}

@property (nonatomic, assign) id<AIMICBMHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)theSession;
- (void)sendMessage:(AIMMessage *)message;

@end
