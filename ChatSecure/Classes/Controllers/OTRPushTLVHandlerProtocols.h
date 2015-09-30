//
//  OTRPushTLVHandlerDelegateProtocol.h
//  ChatSecure
//
//  Created by David Chiles on 9/28/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

@protocol OTRPushTLVHandlerDelegate

@required
- (void)receivePushData:(NSData *)tlvData
               username:(NSString *)username
            accountName:(NSString *)accountName
         protocolString:(NSString *)protocolString;

@end

@protocol OTRPushTLVHandlerProtocol

@required
- (void)sendPushData:(NSData *)data
            username:(NSString *)username
         accountName:(NSString *)accountName
            protocol:(NSString *)protocol;

@end