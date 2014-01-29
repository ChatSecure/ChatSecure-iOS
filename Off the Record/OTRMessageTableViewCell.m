//
//  OTRMessageTableViewCell.m
//  Off the Record
//
//  Created by David on 2/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//



#import "OTRMessageTableViewCell.h"
#import "OTRConstants.h"
#import "OTRSettingsManager.h"
#import "OTRSafariActionSheet.h"
#import "OTRAppDelegate.h"

#import "OTRUtilities.h"


static CGFloat const messageTextWidthMax = 180;

@implementation OTRMessageTableViewCell

-(id)initWithMessage:(OTRManagedMessage *)newMessage withDate:(BOOL)newShowDate reuseIdentifier:(NSString*)identifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    if (self) {
        self.showDate = newShowDate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //CreateMessageSentDateLabel
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.dateLabel.textColor = [UIColor grayColor];
        self.dateLabel.textAlignment = NSTextAlignmentCenter;
        self.dateLabel.font = [UIFont boldSystemFontOfSize:sentDateFontSize];
        self.dateLabel.backgroundColor = [UIColor clearColor];
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.dateLabel];
        
        
        //Create bubbleView
        self.bubbleView = [[OTRChatBubbleView alloc] initWithFrame:CGRectZero];
        self.bubbleView.isIncoming = newMessage.isIncomingValue;
        TTTAttributedLabel * label = [OTRMessageTableViewCell defaultLabel];
        label.text = newMessage.message;
        label.delegate = self;
        self.bubbleView.messageTextLabel = label;
        
        [self.contentView addSubview:self.bubbleView];
        [self setupConstraints];
        
        [self setMessage:newMessage];
    }
    
    return self;
    
}

-(void)setMessage:(OTRManagedMessage *)newMessage
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(message))];
    _message = newMessage;
    [self didChangeValueForKey:NSStringFromSelector(@selector(message))];
    
    self.bubbleView.messageTextLabel.text = self.message.message;
    self.bubbleView.isIncoming = self.message.isIncomingValue;
    
    [self.bubbleView setIsDelivered:self.message.isDeliveredValue animated:NO];
    
    CGFloat messageSentDateLabelHeight = 0;
    
    if (self.showDate) {
        self.dateLabel.text = [[OTRMessageTableViewCell defaultDateFormatter] stringFromDate:newMessage.date];
        
        messageSentDateLabelHeight = messageSentDateLabelHeight;
    } else {
        self.dateLabel.text = nil;
    }
    
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
}

-(void)setupConstraints
{
    ///bubble View
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.bubbleView
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.dateLabel
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1.0
                                                                    constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.bubbleView
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.bubbleView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    //dateLabel
    constraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeWidth
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    [self removeConstraint:dateHeightConstraint];
    CGFloat dateheight = 0.0;
    if (self.showDate) {
        dateheight = sentDateFontSize+5;
    }
    
    dateHeightConstraint = [NSLayoutConstraint constraintWithItem:self.dateLabel
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1.0
                                               constant:dateheight];
    [self addConstraint:dateHeightConstraint];
    
}

+(CGSize)messageTextLabelSize:(NSString *)message
{
    TTTAttributedLabel * label = [OTRMessageTableViewCell defaultLabel];
    label.text = message;
    return  [label sizeThatFits:CGSizeMake(messageTextWidthMax, CGFLOAT_MAX)];
}


+(TTTAttributedLabel *)defaultLabel
{
    TTTAttributedLabel * messageTextLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    messageTextLabel.backgroundColor = [UIColor clearColor];
    messageTextLabel.numberOfLines = 0;
    messageTextLabel.dataDetectorTypes = UIDataDetectorTypeLink;
    messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        messageTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    } else {
        CGFloat messageTextSize = [OTRSettingsManager floatForOTRSettingKey:kOTRSettingKeyFontSize];
        messageTextLabel.font = [UIFont systemFontOfSize:messageTextSize];
    }
    return messageTextLabel;
}



//Label Delegate
- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url
{
    OTRSafariActionSheet * action = [[OTRSafariActionSheet alloc] initWithUrl:url];
    [action showInView:self.superview.superview];
}

-(void)attributedLabelDidSelectDelete:(TTTAttributedLabel *)label
{
    [self.message MR_deleteEntity];
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    
}

+ (CGFloat)heightForMesssage:(NSString *)message showDate:(BOOL)showDate
{
    CGFloat dateHeight = 0;
    if (showDate) {
        dateHeight = sentDateFontSize+5;
    }
    TTTAttributedLabel * label = [self defaultLabel];
    label.text = message;
    CGSize labelSize = [label sizeThatFits:CGSizeMake(180, CGFLOAT_MAX)];
    
    CGFloat padding = 12.0;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        padding = 16.0;
    }
    
    return labelSize.height + padding + dateHeight;
}

+ (NSDateFormatter *)defaultDateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, YYYY h:mm a"];
    });
    return dateFormatter;
}



@end
