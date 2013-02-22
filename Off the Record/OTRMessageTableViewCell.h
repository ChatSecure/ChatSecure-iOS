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

@interface OTRMessageTableViewCell : UITableViewCell <TTTAttributedLabelDelegate>

@property (nonatomic, strong) OTRManagedMessage * message;
@property (nonatomic, strong) UILabel * messageSentDateLabel;
@property (nonatomic, strong) UIImageView *messageBackgroundImageView;
@property (nonatomic, strong) TTTAttributedLabel *messageTextLabel;
@property (nonatomic, strong) UIImageView * messageDeliverdImageView;
@property (nonatomic) BOOL showDate;



-(id)initWithMessage:(OTRManagedMessage *)message withDate:(BOOL)showDate reuseIdentifier:(NSString*)identifier;

-(void)showDeliveredAnimated:(BOOL)animated;

+(CGSize)messageTextLabelSize:(NSString *)message;

@end
