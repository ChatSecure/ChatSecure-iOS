//
//  OTRIncomingMessage.h
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRBaseMessage.h"

@interface OTRIncomingMessage : OTRBaseMessage <OTRMessageProtocol>

@property (nonatomic) BOOL read;

@end
