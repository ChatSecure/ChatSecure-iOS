//
//  OTRAcknowledgementViewController.h
//  ChatSecure
//
//  Created by David Chiles on 9/5/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import VTAcknowledgementsViewController;
@import TTTAttributedLabel;

@interface OTRAcknowledgementsViewController : VTAcknowledgementsViewController <TTTAttributedLabelDelegate>

@property (nonatomic, strong, readonly) TTTAttributedLabel *headerLabel;

- (instancetype) initWithHeaderLabel:(TTTAttributedLabel*)headerLabel;

+ (instancetype)defaultAcknowledgementViewController;

@end
