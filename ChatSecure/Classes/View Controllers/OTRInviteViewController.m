//
//  OTRInviteViewController.m
//  ChatSecure
//
//  Created by David Chiles on 7/8/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRInviteViewController.h"
#import "PureLayout.h"
#import "Strings.h"
#import "BButton.h"
#import "OTRAddBuddyQRCodeViewController.h"
#import <MessageUI/MessageUI.h>
#import "OTRAccount.h"
#import "Strings.h"
#import "OTRAppDelegate.h"
#import "OTRTheme.h"
#import "OTRColors.h"
@import OTRAssets;
#import "OTRLanguageManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

static CGFloat const kOTRInvitePadding = 10;

@interface OTRInviteViewController () <MFMessageComposeViewControllerDelegate>

@property (nonatomic) BOOL addedConstraints;

@end

@implementation OTRInviteViewController

- (instancetype)init
{
    if (self = [super init]) {
        _titleImageView = [[UIImageView alloc] initForAutoLayout];
        _subtitleLabel = [[UILabel alloc] initForAutoLayout];
        _subtitleLabel.numberOfLines = 0;
        _subtitleLabel.textColor = [OTRAppDelegate appDelegate].theme.buttonLabelColor;
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES animated:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.navigationItem setHidesBackButton:NO animated:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [OTRAppDelegate appDelegate].theme.mainThemeColor;
    self.title = INVITE_LINK_STRING;
    
    self.titleImageView.image = [UIImage imageNamed:@"invite_success" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    self.titleImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.view addSubview:self.titleImageView];
    [self.view addSubview:self.subtitleLabel];
    
    UIImage *checkImage = [UIImage imageNamed:@"ic-check" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
    UIBarButtonItem *skipButton = [[UIBarButtonItem alloc] initWithImage:checkImage style:UIBarButtonItemStylePlain target:self action:@selector(skipPressed:)];
    self.navigationItem.rightBarButtonItem = skipButton;
    
    NSMutableArray *shareButtons = [[NSMutableArray alloc] initWithCapacity:2];
    
    [shareButtons addObject:[self shareButtonWithIcon:FAEnvelope title:INVITE_LINK_STRING action:@selector(linkShareButtonPressed:)]];
    [shareButtons addObject:[self shareButtonWithIcon:FACamera title:SCAN_QR_STRING action:@selector(qrButtonPressed:)]];
    
    
    self.shareButtons = shareButtons;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    if (!self.addedConstraints) {
        
        [self.titleImageView autoPinToTopLayoutGuideOfViewController:self withInset:kOTRInvitePadding];
        [self.titleImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:0.4];
        [self.titleImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleImageView withOffset:kOTRInvitePadding];
        [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:kOTRInvitePadding];
        [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:kOTRInvitePadding];
        
        self.addedConstraints = YES;
    }
}

- (void)setupShareButtonConstraints
{
    
    BButton *button = [self.shareButtons firstObject];
    [button autoSetDimension:ALDimensionHeight toSize:40];
    [self.shareButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        if (idx == 0){
            [button autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:kOTRInvitePadding];
        } else {
            [button autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.shareButtons[idx - 1] withOffset:kOTRInvitePadding];
            [button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.shareButtons[idx-1]];
            [button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.shareButtons[idx-1]];
        }
        
        if (idx == [self.shareButtons count]-1) {
            [button autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:kOTRInvitePadding];
        }
        [button autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitleLabel withOffset:kOTRInvitePadding];
    }];
}

- (void)setAccount:(OTRAccount *)account
{
    if(![account isEqual:_account]) {
        _account = account;
        
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ %@!\n\n%@",ONBOARDING_SUCCESS_STRING,[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ,self.account.username];
    }
}

- (void)setShareButtons:(NSArray<BButton *> *)shareButtons
{
    if (![_shareButtons isEqual:shareButtons]) {
        [_shareButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
        _shareButtons = shareButtons;
        for (UIButton *button in _shareButtons) {
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [self.view addSubview:button];
        }
        [self setupShareButtonConstraints];
        [self.view setNeedsUpdateConstraints];
    }
}

- (void)skipPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareSMSPressed:(id)sender
{
    MFMessageComposeViewController *messageComposeViewController = [[MFMessageComposeViewController alloc] init];
    messageComposeViewController.messageComposeDelegate = self;
    
    //Todo: Here's where we can set the body
    //[messageComposeViewController setBody:nil];
    
    [self presentViewController:messageComposeViewController animated:YES completion:nil];
}

- (void)qrButtonPressed:(id)sender
{
    __weak typeof(self)weakSelf = self;
    OTRAddBuddyQRCodeViewController *reader = [[OTRAddBuddyQRCodeViewController alloc] initWithAccount:self.account completion:^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    reader.modalPresentationStyle = UIModalPresentationFormSheet;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:reader];
    [self presentViewController:navigationController animated:YES completion:NULL];
}

- (void)linkShareButtonPressed:(id)sender
{
    [ShareController shareAccount:self.account sender:sender viewController:self];
}

- (UIButton *)shareButtonWithIcon:(FAIcon)icon title:(NSString *)title action:(SEL)action
{
    
    BButton *button = [[BButton alloc] initWithFrame:CGRectZero type:BButtonTypeDefault style:BButtonStyleBootstrapV3];
    [button setTitle:title forState:UIControlStateNormal];
    [button addAwesomeIcon:icon beforeTitle:YES];
    button.titleLabel.font = [button.titleLabel.font fontWithSize:14];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma - mark MFMessageComposeViewControllerDelegate Methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end