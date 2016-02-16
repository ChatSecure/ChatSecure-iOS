//
//  OTRAddBuddyQRCodeViewController.m
//  ChatSecure
//
//  Created by David Chiles on 7/9/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAddBuddyQRCodeViewController.h"
#import "OTRStrings.h"
#import "PureLayout.h"
#import "OTRQRCodeReaderDelegate.h"
#import "OTRQRCodeViewController.h"
#import "XMPPURI.h"
#import "OTRAccount.h"
#import "OTRDatabaseManager.h"
#import "NSURL+ChatSecure.h"
#import "OTRLanguageManager.h"

@interface OTRAddBuddyQRCodeViewController ()

@property (nonatomic, strong) OTRQRCodeReaderDelegate *qrCodeDelegate;
@property (nonatomic, strong) UIButton *showOwnQRCodeButton;

@end

@implementation OTRAddBuddyQRCodeViewController

- (instancetype)initWithAccount:(OTRAccount *)account completion:(void (^)(void))completion
{
    if(self = [super initWithCancelButtonTitle:CANCEL_STRING]){
        self.account = account;
        self.qrCodeDelegate = [[OTRQRCodeReaderDelegate alloc] initWithAccount:account];
        self.qrCodeDelegate.completion = completion;
        
        self.delegate = self.qrCodeDelegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *showOwnQRCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    showOwnQRCodeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [showOwnQRCodeButton setTitle:NSLocalizedString(@"My Code", @"Your QR code") forState:UIControlStateNormal];
    [showOwnQRCodeButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [showOwnQRCodeButton addTarget:self action:@selector(showOwnQRCode:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:showOwnQRCodeButton];
    
    [showOwnQRCodeButton autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:8];
    [showOwnQRCodeButton autoSetDimension:ALDimensionHeight toSize:40];
    [showOwnQRCodeButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    self.showOwnQRCodeButton = showOwnQRCodeButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view bringSubviewToFront:self.showOwnQRCodeButton];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


- (void)showOwnQRCode:(id)sender
{
    NSSet <NSNumber*> *fingerprintTypes = [NSSet setWithArray:@[@(OTRFingerprintTypeOTR)]];
    [self.account generateShareURLWithFingerprintTypes:fingerprintTypes completion:^(NSURL *shareURL, NSError *error) {
        if (shareURL) {
            OTRQRCodeViewController *qrCodeViewController = [[OTRQRCodeViewController alloc] initWithQRString:shareURL.absoluteString];
            [self.navigationController pushViewController:qrCodeViewController animated:YES];
        } else {
            NSLog(@"Error generating shareURL for %@: %@", self.account.username, error);
        }
        
    }];
}
@end
