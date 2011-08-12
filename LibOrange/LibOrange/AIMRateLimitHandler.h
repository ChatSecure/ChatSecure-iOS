//
//  AIMRateLimitHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMRateParamsReply.h"
#import "AIMSession.h"
#import "AIMRateNotificationInfo.h"
#import "AIMRateParamsChange.h"

@class AIMRateLimitHandler;

@protocol AIMRateLimitHandlerDelegate <NSObject>

@optional
- (void)aimRateLimitHandler:(AIMRateLimitHandler *)handler gotRateAlert:(AIMRateNotificationInfo *)info;

@end

@interface AIMRateLimitHandler : NSObject <AIMSessionHandler> {
    AIMSession * session;
	AIMRateParamsReply * initialParams;
	id<AIMRateLimitHandlerDelegate> delegate;
}

@property (nonatomic, assign) id<AIMRateLimitHandlerDelegate> delegate;
@property (nonatomic, retain) AIMRateParamsReply * initialParams; // currently unused

- (id)initWithSession:(AIMSession *)theSession;

@end
