//
//  OTRMessageTableViewCell.h
//  Off the Record
//
//  Created by David on 2/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRManagedMessage.h"
#import "TTTAttributedLabel.h"
#import "OTRChatBubbleView.h"

@interface OTRMessageTableViewCell : UITableViewCell <TTTAttributedLabelDelegate>
{
    NSLayoutConstraint * dateHeightConstraint;
}

@property (nonatomic, strong) OTRManagedMessage * message;
@property (nonatomic, strong) UILabel * dateLabel;
@property (nonatomic) BOOL showDate;

@property (nonatomic, strong) OTRChatBubbleView * bubbleView;


-(id)initWithMessage:(OTRManagedMessage *)message withDate:(BOOL)showDate reuseIdentifier:(NSString*)identifier;

+ (CGSize)messageTextLabelSize:(NSString *)message;

+ (CGFloat)heightForMesssage:(NSString *)message showDate:(BOOL)showDate;

@end
