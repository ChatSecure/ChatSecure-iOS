//
//  OTRConversationCell.m
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationCell.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRDatabaseManager.h"
#import "OTRMediaItem.h"
#import "OTRImageItem.h"
#import "OTRAudioItem.h"
#import "OTRVideoItem.h"
@import OTRAssets;
@import YapDatabase;
#import "ChatSecureCoreCompat-Swift.h"

@interface OTRConversationCell ()

@property (nonatomic, strong) NSArray *verticalConstraints;
@property (nonatomic, strong) NSArray *accountHorizontalConstraints;

@end

@implementation OTRConversationCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.showAccountLabel = NO;
        
        UIColor *darkGreyColor = [UIColor colorWithWhite:.45 alpha:1.0];
        UIColor *lightGreyColor = [UIColor colorWithWhite:.6 alpha:1.0];
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.dateLabel.textColor = darkGreyColor;
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]+2.0];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.nameLabel.textColor = darkGreyColor;
        
        self.conversationLabel = [[UILabel alloc] init];
        self.conversationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.conversationLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.conversationLabel.numberOfLines = 0;
        self.conversationLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.conversationLabel.textColor = lightGreyColor;
        
        self.accountLabel = [[UILabel alloc] init];
        self.accountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        
        [self.contentView addSubview:self.dateLabel];
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.conversationLabel];
        
    }
    return self;
}

- (void)setShowAccountLabel:(BOOL)showAccountLabel
{
    _showAccountLabel = showAccountLabel;
    
    if (!self.showAccountLabel) {
        [self.accountLabel removeFromSuperview];
    }
    else {
        [self.contentView addSubview:self.accountLabel];
    }
}

- (void)setThread:(id <OTRThreadOwner>)thread
{
    [super setThread:thread];
    NSString * nameString = [thread threadName];
    
    self.nameLabel.text = nameString;
    
    __block OTRAccount *account = nil;
    __block id <OTRMessageProtocol> lastMessage = nil;
    __block NSUInteger unreadMessages = 0;
    __block OTRMediaItem *mediaItem = nil;
    
    /// this is so we can show who sent a group message
    __block OTRXMPPBuddy *groupBuddy = nil;
    
    [[OTRDatabaseManager sharedInstance].uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [transaction objectForKey:[thread threadAccountIdentifier] inCollection:[OTRAccount collection]];
        unreadMessages = [thread numberOfUnreadMessagesWithTransaction:transaction];
        lastMessage = [thread lastMessageWithTransaction:transaction];
        groupBuddy = [lastMessage buddyWithTransaction:transaction];
        if (lastMessage.messageMediaItemKey) {
            mediaItem = [OTRMediaItem fetchObjectWithUniqueID:lastMessage.messageMediaItemKey transaction:transaction];
        }
    }];
    
    self.accountLabel.text = account.username;
    
    UIFont *currentFont = self.conversationLabel.font;
    CGFloat fontSize = currentFont.pointSize;
    NSError *messageError = lastMessage.messageError;
    NSString *messageText = lastMessage.messageText;
    if (!messageText) {
        messageText = @"";
    }
    
    NSString *messageTextPrefix = @"";
    if (!lastMessage.isMessageIncoming) {
        NSString *you = GROUP_INFO_YOU().localizedCapitalizedString;
        messageTextPrefix = [NSString stringWithFormat:@"%@: ", you];
    } else if (thread.isGroupThread) {
        NSString *displayName = groupBuddy.displayName;
        if (displayName.length) {
            messageTextPrefix = [NSString stringWithFormat:@"%@: ", displayName];
        }
    }
    
    if (messageError &&
        !messageError.isAutomaticDownloadError) {
        if (!messageText.length) {
            messageText = ERROR_STRING();
        }
        self.conversationLabel.text = [NSString stringWithFormat:@"⚠️ %@", messageText];
    } else if (mediaItem) {
        self.conversationLabel.text = [messageTextPrefix stringByAppendingString:mediaItem.displayText];
    } else {
        self.conversationLabel.text = [messageTextPrefix stringByAppendingString:messageText];
    }
    if (unreadMessages > 0) {
        //unread message
        self.nameLabel.font = [UIFont boldSystemFontOfSize:fontSize];
        if (@available(iOS 13.0, *)) {
            self.nameLabel.textColor = UIColor.labelColor;
        } else {
            self.nameLabel.textColor = UIColor.blackColor;
        }
    } else {
        self.nameLabel.font = [UIFont systemFontOfSize:fontSize];
        self.nameLabel.textColor = [UIColor colorWithWhite:.45 alpha:1.0];
    }
    self.dateLabel.textColor = self.nameLabel.textColor;
    
    [self updateDateString:lastMessage.messageDate];
}



- (void)updateDateString:(NSDate *)date
{
    self.dateLabel.text = [self dateString:date];
}

- (NSString *)dateString:(NSDate *)messageDate
{
    if (!messageDate) {
        return @"";
    }
    NSTimeInterval timeInterval = fabs([messageDate timeIntervalSinceNow]);
    NSString * dateString = nil;
    if (timeInterval < 60){
        dateString = NSLocalizedString(@"Now", @"");
    }
    else if (timeInterval < 60*60) {
        int minsInt = timeInterval/60;
        NSString * minString = NSLocalizedString(@"mins", @"");
        if (minsInt == 1) {
            minString = NSLocalizedString(@"min", @"");
        }
        dateString = [NSString stringWithFormat:@"%d %@",minsInt,minString];
    }
    else if (timeInterval < 60*60*24){
        // show time in format 11:00 PM
        dateString = [NSDateFormatter localizedStringFromDate:messageDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
    else if (timeInterval < 60*60*24*7) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEE" options:0 locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
        
    }
    else if (timeInterval < 60*60*25*365) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMM" options:0
                                                                   locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    }
    else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMMYYYY" options:0
                                                                    locale:[NSLocale currentLocale]];
        dateString = [dateFormatter stringFromDate:messageDate];
    }
    
    
    
    return dateString;
}

- (void)updateConstraints
{
    NSDictionary *views = @{@"imageView": self.avatarImageView,
                            @"conversationLabel": self.conversationLabel,
                            @"dateLabel":self.dateLabel,
                            @"nameLabel":self.nameLabel,
                            @"conversationLabel":self.conversationLabel,
                            @"accountLabel":self.accountLabel};
    
    NSDictionary *metrics = @{@"margin":[NSNumber numberWithFloat:OTRBuddyImageCellPadding]};
    if (!self.addedConstraints) {
        
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[nameLabel]->=0-[dateLabel]-margin-|"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[conversationLabel]-margin-|"
                                                                                 options:0
                                                                                 metrics:metrics
                                                                                   views:views]];
        
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[dateLabel]" options:0 metrics:metrics
                                                                                   views:views]];
        
        
    }
    
    if([self.accountHorizontalConstraints count])
    {
        [self.contentView removeConstraints:self.accountHorizontalConstraints];
    }
    
    if([self.verticalConstraints count]) {
        [self.contentView removeConstraints:self.verticalConstraints];
    }
    
    if (self.showAccountLabel) {
        self.accountHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[accountLabel]|"
                                                                                    options:0
                                                                                    metrics:metrics
                                                                                      views:views];
        
        self.verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[nameLabel][conversationLabel][accountLabel]-margin-|"
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:views];
        
    }
    else {
        self.accountHorizontalConstraints = @[];
        
        self.verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[nameLabel(15)][conversationLabel]-margin-|"
                                                                           options:0
                                                                           metrics:metrics
                                                                             views:views];
    }
    if([self.accountHorizontalConstraints count]) {
        [self.contentView addConstraints:self.accountHorizontalConstraints];
    }
    
    [self.contentView addConstraints:self.verticalConstraints];
    [super updateConstraints];
}

@end
