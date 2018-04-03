//
//  XMPPServerInfoCell.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;
@import XLForm;
#import "OTRXMPPServerInfo.h"

NS_ASSUME_NONNULL_BEGIN
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

- (void) setServerInfo:(OTRXMPPServerInfo*)serverInfo;
/** This must be called for actions to work */
- (void) setServerInfo:(OTRXMPPServerInfo*)serverInfo parentViewController:(UIViewController*)parentViewController;

@property (nonatomic, copy, nullable) void (^domainAction)(XMPPServerInfoCell *cell, id sender);
@property (nonatomic, copy, nullable) void (^privacyPolicyAction)(XMPPServerInfoCell *cell, id sender);
@property (nonatomic, copy, nullable) void (^onionAction)(XMPPServerInfoCell *cell, id sender);
@property (nonatomic, copy, nullable) void (^twitterAction)(XMPPServerInfoCell *cell, id sender);

@end

@interface XMPPServerInfoCell(XLForm)
/** This is a wrapper for setServerInfo:parentViewController: that only works when used within an XLFormViewController */
- (void) setupWithParentViewController:(UIViewController*)parentViewController;
@end
NS_ASSUME_NONNULL_END
