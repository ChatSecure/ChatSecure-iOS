//
//  OTRPushTLVHandler.h
//  ChatSecure
//
//  Created by David Chiles on 9/28/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRTLVHandler.h"
#import "OTRPushTLVHandlerDelegateProtocol.h"
@class OTRKit;

@interface OTRPushTLVHandler : NSObject <OTRTLVHandler>

@property (nonatomic, weak, readonly) id<OTRPushTLVHandlerDelegate> delegate;
@property (nonatomic, weak, readwrite) OTRKit *otrKit;

- (instancetype)initWithDelegate:(id<OTRPushTLVHandlerDelegate>)delegate;

- (void)sendPushData:(NSData *)data username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol;

@end
