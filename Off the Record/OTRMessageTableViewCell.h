//
//  OTRMessageTableViewCell.h
//  Off the Record
//
//  Created by David on 2/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"


@class OTRMessage;
@class OTRChatBubbleView;

@interface OTRMessageTableViewCell : UITableViewCell <TTTAttributedLabelDelegate>
{
    NSLayoutConstraint * dateHeightConstraint;
}

@property (nonatomic, strong) OTRMessage *message;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic) BOOL showDate;

@property (nonatomic, strong) OTRChatBubbleView * bubbleView;

+ (CGSize)messageTextLabelSize:(NSString *)message;

+ (CGFloat)heightForMesssage:(NSString *)message showDate:(BOOL)showDate;

+ (NSString *)reuseIdentifier;

@end
