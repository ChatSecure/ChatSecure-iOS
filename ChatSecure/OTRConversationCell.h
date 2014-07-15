//
//  OTRConversationCell.h
//  Off the Record
//
//  Created by David Chiles on 3/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyImageCell.h"

@interface OTRConversationCell : OTRBuddyImageCell

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *conversationLabel;
@property (nonatomic, strong) UILabel *accountLabel;

@property (nonatomic) BOOL showAccountLabel;

- (void)updateDateString:(NSDate *)date;

@end
