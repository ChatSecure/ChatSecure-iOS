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

@interface OTRPushTLVHandler : NSObject <OTRTLVHandler>

@property (nonatomic, weak, readonly) id<OTRPushTLVHandlerDelegate> delegate;

- (instancetype)initWithDelegate:(id<OTRPushTLVHandlerDelegate>)delegate;

@end
