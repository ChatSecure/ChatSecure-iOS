//
//  OTRWelcomeViewController.m
//  ChatSecure
//
//  Created by David Chiles on 5/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRWelcomeViewController.h"
#import "PureLayout.h"
#import "OTRWelcomeAccountTableViewDelegate.h"
#import "OTRImages.h"
#import "OTRBaseLoginViewController.h"
#import "OTRXLFormCreator.h"
#import "OTRXMPPLoginHandler.h"
#import "OTRXMPPCreateAccountHandler.h"
#import "OTRGoogleOAuthXMPPAccount.h"
#import "OTRGoolgeOAuthLoginHandler.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "OTRSecrets.h"
#import "OTRConstants.h"
#import "OTRDatabaseManager.h"
#import "OTRChatSecureIDCreateAccountHandler.h"
#import "OTRAdvancedWelcomeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRCircleButtonView.h"

@interface OTRWelcomeViewController ()

@property (nonatomic, strong, readonly) UIButton *skipButton;
@property (nonatomic, strong, readonly) UIButton *advancedButton;

@end

#warning Strings need to be added to localization once finalized

@implementation OTRWelcomeViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.showNavigationBar = NO;
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIFont *font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline] size:0];
    _skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.skipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.skipButton addTarget:self action:@selector(skipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.skipButton setTitle:NSLocalizedString(@"Skip", @"skip account creation") forState:UIControlStateNormal];
    [self.skipButton.titleLabel setFont:font];
    [self.skipButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.skipButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    
    _advancedButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.advancedButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.advancedButton addTarget:self action:@selector(advancedButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.advancedButton.titleLabel setFont:font];
    [self.advancedButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.advancedButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self.advancedButton setTitle:NSLocalizedString(@"Login", @"advanced account setup") forState:UIControlStateNormal];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _brandImageView = [[UIImageView alloc] initForAutoLayout];
    self.brandImageView.image = [UIImage imageNamed:@"chatsecure_logo_transparent"];
    
    _createButton = [[OTRCircleButtonView alloc] initWithFrame:CGRectZero title:NSLocalizedString(@"Sign Up", @"create new account") image:[UIImage imageNamed:@"XMPPCreateAccount"] imageSize:CGSizeMake(65, 65) circleSize:CGSizeMake(100, 100) actionBlock:^{
        [self didTapCreateChatID:self.createButton];
    }];
    [self.view addSubview:self.createButton];
    
    _anonymousButton = [[OTRCircleButtonView alloc] initWithFrame:CGRectZero title:NSLocalizedString(@"Anonymous", @"create anonymous account") image:[UIImage imageNamed:@"Tor_Onion"] imageSize:CGSizeMake(85, 85) circleSize:CGSizeMake(100, 100) actionBlock:^{
        [self didTapCreateAnonymousAccount:self.anonymousButton];
    }];
    
    [self.view addSubview:self.anonymousButton];
    [self.view addSubview:self.brandImageView];
    [self.view addSubview:self.advancedButton];
    [self.view addSubview:self.skipButton];
    
    [self addBaseConstraints];
    [self.view setNeedsUpdateConstraints];
}




- (void)addBaseConstraints
{
    CGFloat padding = 30.0f;
    [self.advancedButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.createButton];
    [self.advancedButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:padding];
    [self.skipButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.anonymousButton];
    [self.skipButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:padding];
    
    [self.brandImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.brandImageView autoConstrainAttribute:ALAttributeHorizontal toAttribute:ALAttributeHorizontal ofView:self.view withMultiplier:0.5];
    
    [self.createButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.createButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:padding];
    
    [self.anonymousButton autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.anonymousButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:padding];
}

- (void)didTapCreateChatID:(id)sender
{
    OTRBaseLoginViewController *createAccountViewController = [[OTRBaseLoginViewController alloc] initWithForm:[OTRXLFormCreator formForAccountType:OTRAccountTypeJabber createAccount:YES] style:UITableViewStyleGrouped];
    createAccountViewController.createLoginHandler = [[OTRXMPPCreateAccountHandler alloc] init];
    createAccountViewController.account = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeJabber];
    createAccountViewController.completionBlock = self.completionBlock;
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void)didTapCreateAnonymousAccount:(id)sender
{
    OTRBaseLoginViewController *createAccountViewController = [[OTRBaseLoginViewController alloc] initWithForm:[OTRXLFormCreator formForAccountType:OTRAccountTypeXMPPTor createAccount:YES] style:UITableViewStyleGrouped];
    createAccountViewController.createLoginHandler = [[OTRXMPPCreateAccountHandler alloc] init];
    createAccountViewController.account = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeXMPPTor];
    createAccountViewController.completionBlock = self.completionBlock;
    [self.navigationController pushViewController:createAccountViewController animated:YES];
}

- (void) skipButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) advancedButtonPressed:(id)sender {
    OTRAdvancedWelcomeViewController *adv = [[OTRAdvancedWelcomeViewController alloc] init];
    [self.navigationController pushViewController:adv
                                         animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:!self.showNavigationBar animated:animated];
    if (self.showNavigationBar) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(skipButtonPressed:)];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}
@end
