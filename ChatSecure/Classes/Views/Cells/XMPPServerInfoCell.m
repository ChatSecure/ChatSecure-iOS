//
//  XMPPServerInfoCell.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XMPPServerInfoCell.h"
#import "NSURL+ChatSecure.h"
@import OTRAssets;

NSString *const kOTRFormRowDescriptorTypeXMPPServer = @"kOTRFormRowDescriptorTypeXMPPServer";

@implementation XMPPServerInfoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.onionImageView.layer.minificationFilter = kCAFilterTrilinear;
    self.logoImageView.layer.minificationFilter = kCAFilterTrilinear;
    self.countryImageView.layer.minificationFilter = kCAFilterTrilinear;
}

+ (void)load
{
    NSBundle *bundle = [OTRAssets resourcesBundle];
    NSString *path = bundle.bundlePath;
    NSString *bundleName = [path lastPathComponent];
    NSString *class = [NSString stringWithFormat:@"%@/%@", bundleName, NSStringFromClass([self class])];
    [[XLFormViewController cellClassesForRowDescriptorTypes] setObject:class forKey:kOTRFormRowDescriptorTypeXMPPServer];
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

- (void) setServerInfo:(OTRXMPPServerInfo*)serverInfo parentViewController:(UIViewController*)parentViewController {
    [self setServerInfo:serverInfo];
    [self setDomainAction:^(XMPPServerInfoCell * _Nonnull cell, id _Nonnull sender) {
        NSURL *url = serverInfo.websiteURL;
        // If there's no website URL, try using the domain
        if (!url) {
            NSString *urlString = [NSString stringWithFormat:@"https://%@", serverInfo.domain];
            url = [NSURL URLWithString:urlString];
        }
        [url promptToShowURLFromViewController:parentViewController sender:sender];
    }];
    [self setPrivacyPolicyAction:^(XMPPServerInfoCell * _Nonnull cell, id _Nonnull sender) {
        [serverInfo.privacyPolicyURL  promptToShowURLFromViewController:parentViewController sender:sender];
    }];
    [self setOnionAction:^(XMPPServerInfoCell * _Nonnull cell, id _Nonnull sender) {
        NSURL *url = [NSURL URLWithString:@"https://en.wikipedia.org/wiki/.onion"];
        [url promptToShowURLFromViewController:parentViewController sender:sender];
    }];
    [self setTwitterAction:^(XMPPServerInfoCell * _Nonnull cell, id _Nonnull sender) {
        [serverInfo.twitterURL promptToShowURLFromViewController:parentViewController sender:sender];
    }];
}

- (void) setServerInfo:(OTRXMPPServerInfo*)info {
    if (!info) { return; }
    UIImage *image = info.logoImage;
    if (!image) {
        image = [UIImage imageNamed:@"xmpp" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    }
    self.logoImageView.image = image;
    NSString *name = info.name;
    if (!info.name) {
        name = CUSTOM_STRING();
    }
    self.serverNameLabel.text = name;
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
    if (info.privacyPolicyURL) {
        self.privacyPolicyButton.enabled = YES;
        self.privacyPolicyButton.hidden = NO;
    } else {
        self.privacyPolicyButton.enabled = NO;
        self.privacyPolicyButton.hidden = YES;
    }
    UIImage *countryImage = [UIImage imageNamed:info.countryCode inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    if (countryImage) {
        self.countryImageView.hidden = NO;
    } else {
        self.countryImageView.hidden = YES;
    }
    self.countryImageView.image = countryImage;
}

- (void)update
{
    [super update];
    OTRXMPPServerInfo *info = self.rowDescriptor.value;
    [self setServerInfo:info];
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
        self.domainAction(self, sender);
    }
}

- (IBAction)privacyPolicyButtonPressed:(id)sender {
    if (self.privacyPolicyAction) {
        self.privacyPolicyAction(self, sender);
    }
}

- (IBAction)onionButtonPressed:(id)sender {
    if (self.onionAction) {
        self.onionAction(self, sender);
    }
}

- (IBAction)twitterButtonPressed:(id)sender {
    if (self.twitterAction) {
        self.twitterAction(self, sender);
    }
}

@end

@implementation XMPPServerInfoCell(XLForm)
/** This is a wrapper for setServerInfo:parentViewController: that only works when used within an XLFormViewController */
- (void) setupWithParentViewController:(UIViewController*)parentViewController {
    OTRXMPPServerInfo *info = nil;
    if ([self.rowDescriptor.value isKindOfClass:[OTRXMPPServerInfo class]]) {
        info = self.rowDescriptor.value;
    }
    if (info) {
        [self setServerInfo:info parentViewController:parentViewController];
    }
}
@end
