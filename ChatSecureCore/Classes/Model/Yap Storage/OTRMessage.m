//
//  OTRMessage.m
//  ChatSecure
//
//  Created by David Chiles on 11/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRMessage.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"

@implementation OTRMessage

- (id)initWithCoder:(NSCoder *)aDecoder
{
    id possibleNumber = [self decodeValueForKey:@"incoming" withCoder:aDecoder modelVersion:0];
    if ([possibleNumber isKindOfClass:[NSNumber class]]) {
        BOOL incoming = [((NSNumber *)possibleNumber) boolValue];
        //Casting to OTRMessage to silence warnings.
        if (incoming) {
            return (OTRMessage *)[[OTRIncomingMessage alloc] initWithCoder:aDecoder];
        } else {
            return (OTRMessage *)[[OTROutgoingMessage alloc] initWithCoder:aDecoder];
        }
    }
    // We should never get here. If an object was serialized as an OTRMessage from a previous version of the app it should be deserialized as OTRIncomingMessage or OTROutgoingMessage.
    return [self init];
}

@end
