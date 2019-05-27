//
//  OTROutgoingMessage.h
//  ChatSecure
//
//  Created by David Chiles on 11/10/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRBaseMessage.h"
@import YapDatabase;

NS_ASSUME_NONNULL_BEGIN
@interface OTROutgoingMessage : OTRBaseMessage <OTRMessageProtocol>

/** OUTGOING ONLY. The date that the message left the device and went on the wire.*/
@property (nonatomic, strong, nullable) NSDate *dateSent;

/** OUTGOING ONLY. The date that the message is acknowledged by the server. Only relevant if the stream supporrts XEP-0198 at the time of sending*/
@property (nonatomic, strong, nullable) NSDate *dateAcked;

/** OUTGOING ONLY. The date the message is deliverd to the other client. Only relevant if the other client supports XEP-0184. There is no way to query support */
@property (nonatomic, strong, nullable) NSDate *dateDelivered;

/** Mark message as deliverd via XEP-0184.*/
@property (nonatomic, getter = isDelivered) BOOL delivered;

@end
NS_ASSUME_NONNULL_END
