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
#import "NSURL+ChatSecure.h"

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    //self.subtitleLabel.text = @"Tell your friends about ChatSecure";
    
    [self.view addSubview:self.titleImageView];
    [self.view addSubview:self.subtitleLabel];
    
    UIBarButtonItem *skipButton = [[UIBarButtonItem alloc] initWithTitle:SKIP_STRING style:UIBarButtonItemStylePlain target:self action:@selector(skipPressed:)];
    self.navigationItem.rightBarButtonItem = skipButton;
    
    NSMutableArray *shareButtons = [[NSMutableArray alloc] initWithCapacity:3];
    
    if ([MFMessageComposeViewController canSendText]) {
        [shareButtons addObject:[self shareButtonWithIcon:FAEnvelope title:@"Invite SMS" action:@selector(shareSMSPressed:)]];
    }
    
    [shareButtons addObject:[self shareButtonWithIcon:FAGlobe title:@"Share Invite Link" action:@selector(linkShareButtonPressed:)]];
    [shareButtons addObject:[self shareButtonWithIcon:FACamera title:@"Scan QR" action:@selector(qrButtonPressed:)]];
    
    
    self.shareButtons = shareButtons;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    if (!self.addedConstraints) {
        
        [self.titleImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
        [self.titleImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:0.4];
        
        [self.subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleImageView withOffset:kOTRInvitePadding];
        [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:kOTRInvitePadding];
        [self.subtitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:kOTRInvitePadding];
        
        self.addedConstraints = YES;
    }
}

- (void)setupShareButtonConstraints
{
    
    [self.shareButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        if (idx == 0){
            [button autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:kOTRInvitePadding];
        } else {
            [button autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.shareButtons[idx - 1]];
            [button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.shareButtons[idx-1]];
            [button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.shareButtons[idx-1]];
        }
        
        if (idx == [self.shareButtons count]-1) {
            [button autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:kOTRInvitePadding];
        }
        [button autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.subtitleLabel withOffset:kOTRInvitePadding];
    }];
}

- (void)setShareButtons:(NSArray *)shareButtons
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
    NSURL *url = [self shareURL];
    
    NSArray *activityItems = @[url];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (UIButton *)shareButtonWithIcon:(FAIcon)icon title:(NSString *)title action:(SEL)action
{
    
    BButton *button = [[BButton alloc] initWithFrame:CGRectZero color:[UIColor clearColor] style:BButtonStyleBootstrapV3];
    [button setTitle:title forState:UIControlStateNormal];
    [button addAwesomeIcon:icon beforeTitle:YES];
    button.titleLabel.font = [button.titleLabel.font fontWithSize:14];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (NSURL *)shareURL {
    NSURL *baseURL = [NSURL otr_shareBaseURL];
    return [NSURL otr_shareLink:baseURL.absoluteString username:self.account.username fingerprint:nil base64Encoded:YES];
}

#pragma - mark MFMessageComposeViewControllerDelegate Methods

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

+ (void) showInviteFromVC:(UIViewController *)vc withAccount:(OTRAccount *)account {
    NSParameterAssert([NSThread currentThread] == [NSThread mainThread]);
    NSParameterAssert(vc != nil);
    NSParameterAssert(account != nil);
    if (!vc || !account) {
        return;
    }
    OTRInviteViewController *inviteViewController = [[OTRInviteViewController alloc] init];
    inviteViewController.account = account;
    [inviteViewController.navigationItem setHidesBackButton:YES animated:YES];
    [vc.navigationController pushViewController:inviteViewController animated:YES];
}

@end
