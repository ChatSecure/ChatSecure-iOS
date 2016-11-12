//
//  OTRMessage+JSQMessageData.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
@import JSQMessagesViewController;

@interface OTRBaseMessage (JSQMessageData)

@end

@interface OTRIncomingMessage (JSQMessageData) <JSQMessageData>

@end


@interface OTROutgoingMessage (JSQMessageData) <JSQMessageData>

@end
