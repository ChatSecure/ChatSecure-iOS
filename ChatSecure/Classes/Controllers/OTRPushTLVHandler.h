//
//  OTRPushTLVHandler.h
//  ChatSecure
//
//  Created by David Chiles on 9/28/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRTLVHandler.h"
#import <ChatSecureCore/OTRPushTLVHandlerProtocols.h>
@class OTRKit;

@interface OTRPushTLVHandler : NSObject <OTRTLVHandler, OTRPushTLVHandlerProtocol>

@property (nonatomic, weak, readwrite) id<OTRPushTLVHandlerDelegate> delegate;
@property (nonatomic, weak, readwrite) OTRKit *otrKit;

- (instancetype)initWithOTRKit:(OTRKit *)otrKit delegate:(id<OTRPushTLVHandlerDelegate>)delegate;

@end
