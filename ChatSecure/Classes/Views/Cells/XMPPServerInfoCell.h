//
//  XMPPServerInfoCell.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XLFormBaseCell.h"
#import "OTRXMPPServerInfo.h"

extern NSString *const kOTRFormRowDescriptorTypeXMPPServer;


@interface XMPPServerInfoCell : XLFormBaseCell

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *serverNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *serverDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *domainButton;
@property (strong, nonatomic) IBOutlet UIButton *privacyPolicyButton;
@property (strong, nonatomic) IBOutlet UIButton *twitterButton;
@property (strong, nonatomic) IBOutlet UIButton *onionButton;
@property (strong, nonatomic) IBOutlet UIImageView *onionImageView;
@property (strong, nonatomic) IBOutlet UIImageView *countryImageView;

@property (nonatomic, copy) void (^domainAction)(XMPPServerInfoCell *cell, OTRXMPPServerInfo *serverInfo);
@property (nonatomic, copy) void (^privacyPolicyAction)(XMPPServerInfoCell *cell, OTRXMPPServerInfo *serverInfo);
@property (nonatomic, copy) void (^onionAction)(XMPPServerInfoCell *cell, OTRXMPPServerInfo *serverInfo);
@property (nonatomic, copy) void (^twitterAction)(XMPPServerInfoCell *cell, OTRXMPPServerInfo *serverInfo);

@end
