//
//  OTRMessagesCollectionViewCell.m
//  Off the Record
//
//  Created by David Chiles on 6/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesCollectionViewCell.h"
#import "OTRMessage.h"
#import "OTRImages.h"

@implementation OTRMessagesCollectionViewCell

- (void)errorImageTap:(UITapGestureRecognizer *)tap
{
    if ([self.actionDelegate respondsToSelector:@selector(messagesCollectionViewCellDidTapError:)]) {
        [self.actionDelegate messagesCollectionViewCellDidTapError:self];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL result = [super canPerformAction:action withSender:sender];
    if (!result) {
        result = (action == @selector(delete:));
    }
    return result;
}

- (void)delete:(id)sender
{
    if ([self.actionDelegate respondsToSelector:@selector(messagesCollectionViewCellDidTapDelete:)]) {
        [self.actionDelegate messagesCollectionViewCellDidTapDelete:self];
    }
}

- (void) setMessage:(OTRMessage*)message {
    if (message.isIncoming) {
        self.textView.textColor = [UIColor blackColor];
    } else {
        self.textView.textColor = [UIColor whiteColor];
    }
    if (message.isTransportedSecurely) {
        
    } else {
       
    }
    if (message.error) {
        
    } else {
        
    }
}

@end
