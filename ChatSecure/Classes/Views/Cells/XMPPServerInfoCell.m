//
//  XMPPServerInfoCell.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XMPPServerInfoCell.h"

NSString *const kOTRFormRowDescriptorTypeXMPPServer = @"kOTRFormRowDescriptorTypeXMPPServer";

@implementation XMPPServerInfoCell

- (void)awakeFromNib {
    // Initialization code
    self.onionImageView.layer.minificationFilter = kCAFilterTrilinear;
    self.logoImageView.layer.minificationFilter = kCAFilterTrilinear;
    self.countryImageView.layer.minificationFilter = kCAFilterTrilinear;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (void)load
{
    [[XLFormViewController cellClassesForRowDescriptorTypes] setObject:NSStringFromClass([self class]) forKey:kOTRFormRowDescriptorTypeXMPPServer];
}

+ (CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor
{
    return 105;
}

- (void) prepareForReuse {
    [super prepareForReuse];
    self.onionAction = nil;
    self.domainAction = nil;
    self.privacyPolicyAction = nil;
    self.twitterAction = nil;
}

- (void)configure
{
    [super configure];
}

- (void)update
{
    [super update];
    OTRXMPPServerInfo *info = self.rowDescriptor.value;
    
    UIImage *image = info.logoImage;
    if (!image) {
        image = [UIImage imageNamed:@"xmpp"];
    }
    self.logoImageView.image = info.logoImage;
    self.serverNameLabel.text = info.name;
    self.serverDescriptionLabel.text = info.serverDescription;
    NSString *domainButtonTitle = [NSString stringWithFormat:@"@%@", info.domain];
    [self.domainButton setTitle:domainButtonTitle forState:UIControlStateNormal];
    if (info.twitterURL) {
        self.twitterButton.enabled = YES;
        self.twitterButton.hidden = NO;
    } else {
        self.twitterButton.enabled = NO;
        self.twitterButton.hidden = YES;
    }
    if (info.onion) {
        self.onionImageView.hidden = NO;
        self.onionButton.hidden = NO;
        self.onionButton.enabled = YES;
    } else {
        self.onionImageView.hidden = YES;
        self.onionButton.hidden = YES;
        self.onionButton.enabled = NO;
    }
    UIImage *countryImage = [UIImage imageNamed:info.countryCode];
    self.countryImageView.image = countryImage;
}

- (void)formDescriptorCellDidSelectedWithFormController:(XLFormViewController *)controller
{
    UIViewController *controllerToPresent = [[self.rowDescriptor.action.viewControllerClass alloc] init];
    
    UIViewController<XLFormRowDescriptorViewController> *selectorViewController = (UIViewController<XLFormRowDescriptorViewController> *)controllerToPresent;
    selectorViewController.rowDescriptor = self.rowDescriptor;
    
    [controller.navigationController pushViewController:selectorViewController animated:YES];
    [controller.tableView deselectRowAtIndexPath:[controller.tableView indexPathForCell:self] animated:YES];
}

- (IBAction)domainButtonPressed:(id)sender {
    if (self.domainAction) {
        self.domainAction(self, self.rowDescriptor.value);
    }
}

- (IBAction)privacyPolicyButtonPressed:(id)sender {
    if (self.privacyPolicyAction) {
        self.privacyPolicyAction(self, self.rowDescriptor.value);
    }
}

- (IBAction)onionButtonPressed:(id)sender {
    if (self.onionAction) {
        self.onionAction(self, self.rowDescriptor.value);
    }
}

- (IBAction)twitterButtonPressed:(id)sender {
    if (self.twitterAction) {
        self.twitterAction(self, self.rowDescriptor.value);
    }
}

@end
