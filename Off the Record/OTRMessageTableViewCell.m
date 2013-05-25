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


#define kOTRRightImageName                   @"MessageBubbleBlue"
#define kOTRLeftImageName                    @"MessageBubbleGray"
#define kOTRDeliveredImageName               @"checkmark"
#define kChatBarHeight1                      40
#define kChatBarHeight4                      94
#define SentDateFontSize                     13
#define DeliveredFontSize                    13
#define MESSAGE_DELIVERED_LABEL_HEIGHT       (DeliveredFontSize +7)
#define MESSAGE_SENT_DATE_LABEL_HEIGHT       (SentDateFontSize+7)
#define MessageFontSize                      16
#define MESSAGE_TEXT_WIDTH_MAX               180
#define MESSAGE_MARGIN_TOP                   7
#define MESSAGE_MARGIN_BOTTOM                10
#define TEXT_VIEW_X                          7   // 40  (with CameraButton)
#define TEXT_VIEW_Y                          2
#define TEXT_VIEW_WIDTH                      249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN                 90
#define ContentHeightMax                     80
#define MESSAGE_SENT_DATE_LABEL_TAG          100
#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG    101
#define MESSAGE_TEXT_LABEL_TAG               102
#define MESSAGE_DELIVERED_LABEL_TAG          103

@implementation OTRMessageTableViewCell

@synthesize message;
@synthesize messageDeliverdImageView;
@synthesize messageBackgroundImageView;
@synthesize messageSentDateLabel;
@synthesize messageTextLabel;
@synthesize showDate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(id)initWithMessage:(OTRManagedMessage *)newMessage withDate:(BOOL)newShowDate reuseIdentifier:(NSString*)identifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    if (self) {
        self.showDate = newShowDate;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //CreateMessageSentDateLabel
        messageSentDateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        messageSentDateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        messageSentDateLabel.tag = MESSAGE_SENT_DATE_LABEL_TAG;
        messageSentDateLabel.textColor = [UIColor grayColor];
        messageSentDateLabel.textAlignment = UITextAlignmentCenter;
        messageSentDateLabel.font = [UIFont boldSystemFontOfSize:SentDateFontSize];
        messageSentDateLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:messageSentDateLabel];
        
        
        //Create messageBackgroundImageView
        messageBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        messageBackgroundImageView.tag = MESSAGE_BACKGROUND_IMAGE_VIEW_TAG;
        [self.contentView addSubview:messageBackgroundImageView];
        
        // Create messageTextLabel.
        messageTextLabel = [OTRMessageTableViewCell defaultLabel];
        messageTextLabel.delegate = self;
        [self.contentView addSubview:messageTextLabel];
        
        //Create MessageDeliveredImageView
        messageDeliverdImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        messageDeliverdImageView.tag = MESSAGE_DELIVERED_LABEL_TAG;
        [self.contentView addSubview:messageDeliverdImageView];
        
        [self setMessage:newMessage];
    }
    
    return self;
    
}

-(void)showDeliveredAnimated:(BOOL)animated
{
    UIImage * _messageDeliveredImage = [UIImage imageNamed:kOTRDeliveredImageName];
    messageDeliverdImageView.image = _messageDeliveredImage;
    CGFloat imageHeight = _messageDeliveredImage.size.height/2;
    CGFloat imageWidth = _messageDeliveredImage.size.width/2;
    CGFloat imageX = (messageBackgroundImageView.frame.origin.x - 20.0);
    CGFloat imageY = messageBackgroundImageView.frame.origin.y + (messageBackgroundImageView.frame.size.height/2) - (imageHeight/2);
    messageDeliverdImageView.frame = CGRectMake(imageX, imageY, imageWidth, imageWidth);
}

-(void)setMessage:(OTRManagedMessage *)newMessage
{
    message = newMessage;
    CGFloat width = self.contentView.frame.size.width;
    
    CGFloat messageFontSize = [OTRSettingsManager floatForOTRSettingKey:kOTRSettingKeyFontSize];
    
    CGFloat messageSentDateLabelHeight = 0;
    
    if (showDate) {
        
        char buffer[22]; // Sep 22, 2012 12:15 PM -- 21 chars + 1 for NUL terminator \0
        time_t time = [message.date timeIntervalSince1970];
        strftime(buffer, 22, "%b %-e, %Y %-l:%M %p", localtime(&time));
        messageSentDateLabel.frame = CGRectMake(-2, 0, width, SentDateFontSize+5);
        messageSentDateLabel.text = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        messageSentDateLabelHeight = MESSAGE_SENT_DATE_LABEL_HEIGHT;
    } else {
        messageSentDateLabel.text = nil;
    }
    
    messageTextLabel.text = message.message;
    messageTextLabel.font = [UIFont systemFontOfSize:messageFontSize];
    CGSize messageTextLabelSize = [messageTextLabel sizeThatFits:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX)];
    
    if (!message.isIncomingValue) { // right message
        UIImage * _messageBubbleBlue = [[UIImage imageNamed:kOTRRightImageName]stretchableImageWithLeftCapWidth:15 topCapHeight:13];
        messageBackgroundImageView.frame = CGRectMake(width-messageTextLabelSize.width-34, messageSentDateLabelHeight+messageFontSize-13, messageTextLabelSize.width+34, messageTextLabelSize.height+12);
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        messageBackgroundImageView.image = _messageBubbleBlue;
        
        messageTextLabel.frame = CGRectMake(width-messageTextLabelSize.width-22, messageSentDateLabelHeight+messageFontSize-9, messageTextLabelSize.width+5, messageTextLabelSize.height);
        messageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    } else {
        UIImage * _messageBubbleGray = [[UIImage imageNamed:kOTRLeftImageName] stretchableImageWithLeftCapWidth:23 topCapHeight:15];
        messageBackgroundImageView.frame = CGRectMake(0, messageSentDateLabelHeight+messageFontSize-13, messageTextLabelSize.width+34, messageTextLabelSize.height+12);
        messageBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        messageBackgroundImageView.image = _messageBubbleGray;
        
        messageTextLabel.frame = CGRectMake(22, messageSentDateLabelHeight+messageFontSize-9, messageTextLabelSize.width+5, messageTextLabelSize.height);
        messageTextLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }
    
    if(message.isDeliveredValue)
    {
        [self showDeliveredAnimated:NO];
    }
    else
    {
        self.messageDeliverdImageView.image = nil;
    }
    
    
    
}

+(CGSize)messageTextLabelSize:(NSString *)message
{
    TTTAttributedLabel * label = [OTRMessageTableViewCell defaultLabel];
    label.text = message;
    return  [label sizeThatFits:CGSizeMake(MESSAGE_TEXT_WIDTH_MAX, CGFLOAT_MAX)];
}


+(TTTAttributedLabel *)defaultLabel
{
    TTTAttributedLabel * messageTextLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    messageTextLabel.tag = MESSAGE_TEXT_LABEL_TAG;
    messageTextLabel.backgroundColor = [UIColor clearColor];
    messageTextLabel.numberOfLines = 0;
    messageTextLabel.dataDetectorTypes = UIDataDetectorTypeLink;
    messageTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    CGFloat messageTextSize = [OTRSettingsManager floatForOTRSettingKey:kOTRSettingKeyFontSize];
    messageTextLabel.font = [UIFont systemFontOfSize:messageTextSize];
    
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

@end
