//
//  OTROutgoingMessageTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 2/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTROutgoingMessageTableViewCell.h"
#import "OTRChatBubbleView.h"

@implementation OTROutgoingMessageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.bubbleView.incoming = NO;
        [self.bubbleView updateLayout];
    }
    return self;
}

@end
