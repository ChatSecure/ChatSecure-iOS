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

/** The method the message is intended to be sent and will be sent */
@property (nonatomic, strong, nonnull) OTRMessageEncryptionInfo *messageSecurityInfo;

@end
