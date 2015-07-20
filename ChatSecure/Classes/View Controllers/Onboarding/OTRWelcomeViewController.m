//
//  OTRWelcomeViewController.m
//  ChatSecure
//
//  Created by David Chiles on 5/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRWelcomeViewController.h"
#import "PureLayout.h"
#import "OTRCircleView.h"
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
    
    _skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.skipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.skipButton addTarget:self action:@selector(skipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.skipButton setTitle:NSLocalizedString(@"Skip", @"skip account creation") forState:UIControlStateNormal];
    _advancedButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.advancedButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.advancedButton addTarget:self action:@selector(advancedButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.advancedButton setTitle:NSLocalizedString(@"Advanced", @"advanced account setup") forState:UIControlStateNormal];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _brandImageView = [[UIImageView alloc] initForAutoLayout];
    self.brandImageView.image = [UIImage imageNamed:@"chatsecure_banner"];
    
    _anonymousLabel = [[UILabel alloc] initForAutoLayout];
    self.anonymousLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.anonymousLabel.numberOfLines = 0;
    self.anonymousLabel.textAlignment = NSTextAlignmentCenter;
    self.anonymousLabel.text = @"Anonymous";
    
    _createLabel = [[UILabel alloc] initForAutoLayout];
    self.createLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.createLabel.numberOfLines = 0;
    self.createLabel.textAlignment = NSTextAlignmentCenter;
    self.createLabel.text = @"Sign Up";
    
    _createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.createButton.backgroundColor = [UIColor lightGrayColor];
    self.createButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createButton addTarget:self action:@selector(didTapCreateChatID:) forControlEvents:UIControlEventTouchUpInside];
    
    self.createButton.contentMode = UIViewContentModeScaleAspectFill;
    self.createButton.imageView.image = [UIImage imageNamed:@"createChatIDImage"];
    
    _createView = [[OTRCircleView alloc] initForAutoLayout];
    [self.createView addSubview:self.createButton];
    
    _anonymousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.anonymousButton.backgroundColor = [UIColor lightGrayColor];
    self.anonymousButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.anonymousButton addTarget:self action:@selector(didTapCreateAnonymousAccount:) forControlEvents:UIControlEventTouchUpInside];
    self.anonymousButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.anonymousButton.imageView.image = [UIImage imageNamed:@"createAnonymousImage"];
    
    _anonymousView = [[OTRCircleView alloc] initForAutoLayout];
    [self.anonymousView addSubview:self.anonymousButton];
    
    [self.view addSubview:self.brandImageView];
    [self.view addSubview:self.createLabel];
    [self.view addSubview:self.anonymousLabel];
    [self.view addSubview:self.createView];
    [self.view addSubview:self.anonymousView];
    
    [self.view addSubview:self.advancedButton];
    [self.view addSubview:self.skipButton];
    
    [self addBaseConstraints];
    [self.view setNeedsUpdateConstraints];
}


- (void)addBaseConstraints
{
    CGFloat padding = 10.0f;
    [self.advancedButton autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:padding];
    [self.advancedButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:padding];
    [self.skipButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:padding];
    [self.skipButton autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:padding];
    
    [self.brandImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.brandImageView autoConstrainAttribute:ALAttributeHorizontal toAttribute:ALAttributeHorizontal ofView:self.view withMultiplier:0.5];
    
    [self.createView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.brandImageView withOffset:10];
    [self.createView autoConstrainAttribute:ALAttributeVertical toAttribute:ALAttributeVertical ofView:self.view withMultiplier:0.5];
    [UIView autoSetPriority:UILayoutPriorityDefaultLow forConstraints:^{
        [self.createView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:0.25];
    }];
    
    [self.createView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.createView];
    
    [UIView autoSetPriority:UILayoutPriorityRequired forConstraints:^{
        [self.createView autoSetDimension:ALDimensionWidth toSize:100 relation:NSLayoutRelationLessThanOrEqual];
    }];
    
    
    [self.createButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    [self.anonymousButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    
    [self.anonymousView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.createView];
    [self.anonymousView autoConstrainAttribute:ALAttributeVertical toAttribute:ALAttributeVertical ofView:self.view withMultiplier:1.5];
    [self.anonymousView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.createView];
    [self.anonymousView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.createView];
    
    [self.createLabel autoAlignAxis:ALAxisVertical toSameAxisOfView:self.createView];
    [self.createLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.createView withOffset:10];
    [self.createLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.createView withMultiplier:1.2];
    
    [self.anonymousLabel autoAlignAxis:ALAxisVertical toSameAxisOfView:self.anonymousView];
    [self.anonymousLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.anonymousView withOffset:10];
    [self.anonymousLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.anonymousView withMultiplier:1.2];
}

- (void)didTapCreateChatID:(id)sender
{
    OTRBaseLoginViewController *createAccountViewController = [[OTRBaseLoginViewController alloc] initWithForm:[OTRXLFormCreator ChatSecureIDForm] style:UITableViewStyleGrouped];
    createAccountViewController.createLoginHandler = [[OTRChatSecureIDCreateAccountHandler alloc] init];
    createAccountViewController.account = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeJabber];
    __weak typeof(self)weakSelf = self;
    [createAccountViewController setSuccessBlock:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf.successBlock) {
            strongSelf.successBlock();
        }
    }];
    
    [self.navigationController pushViewController:createAccountViewController animated:YES];
    NSLog(@"Create Chat ID");
}

- (void)didTapCreateAnonymousAccount:(id)sender
{
    NSLog(@"Moose");
    
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
