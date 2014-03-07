//
//  OTRIncomingMessageTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 2/27/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRIncomingMessageTableViewCell.h"
#import "OTRChatBubbleView.h"

@implementation OTRIncomingMessageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.bubbleView.incoming = YES;
        [self.bubbleView updateLayout];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
