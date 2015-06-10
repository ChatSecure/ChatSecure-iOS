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

@implementation OTRWelcomeAccountInfo

+ (instancetype)accountInfoWithText:(NSString *)text image:(UIImage *)image didSelectBlock:(void (^)(void))didSelectBlock
{
    OTRWelcomeAccountInfo *info = [[OTRWelcomeAccountInfo alloc] init];
    info.labelText = text;
    info.image = image;
    info.didSelectBlock = didSelectBlock;
    
    return info;
}

@end

@interface OTRWelcomeViewController ()

@property (nonatomic, strong) UITableView *accountTableView;

@property (nonatomic) NSLayoutConstraint *accountPickerBottomLayotuConstraint;

@property (nonatomic) CGFloat tableViewHeight;

@property (nonatomic, strong) OTRWelcomeAccountTableViewDelegate *tableViewDelegate;

@end

#warning Strings need to be added to localization once finalized

@implementation OTRWelcomeViewController

- (instancetype)init
{
    if (self = [super init]) {
        self.tableViewHeight = 4*33;
    }
    return self;
}

- (instancetype)initWithDefaultAccountArray
{
    if (self = [self init]) {
        _accountInfoArray = [self defaultAccountArray];
        self.tableViewDelegate = [[OTRWelcomeAccountTableViewDelegate alloc] init];
        self.tableViewDelegate.welcomeAccountInfoArray= self.accountInfoArray;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _chatsecureLabel = [[UILabel alloc] initForAutoLayout];
    self.chatsecureLabel.text = @"ChatSecure";
    
    _stayConnectedLabel = [[UILabel alloc] initForAutoLayout];
    self.stayConnectedLabel.text = @"Stay Connected";
    
    _anonymousLabel = [[UILabel alloc] initForAutoLayout];
    self.anonymousLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.anonymousLabel.numberOfLines = 0;
    self.anonymousLabel.textAlignment = NSTextAlignmentCenter;
    self.anonymousLabel.text = @"Be Anonymous Moose";
    
    _createLabel = [[UILabel alloc] initForAutoLayout];
    self.createLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.createLabel.numberOfLines = 0;
    self.createLabel.textAlignment = NSTextAlignmentCenter;
    self.createLabel.text = @"Create a Chat ID";
    
    _createView = [[OTRCircleView alloc] initForAutoLayout];
    self.createView.backgroundColor = [UIColor lightGrayColor];
    UITapGestureRecognizer *createTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCreateChatID:)];
    [self.createView addGestureRecognizer:createTapGestureRecognizer];
    
    _anonymousView = [[OTRCircleView alloc] initForAutoLayout];
    self.anonymousView.backgroundColor = [UIColor lightGrayColor];
    UITapGestureRecognizer *anonymousTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(didTapCreateAnonymousAccount:)];
    [self.anonymousView addGestureRecognizer:anonymousTapGestureRecognizer];
    
    _accountPickerHeaderView = [[UIView alloc] initForAutoLayout];
    self.accountPickerHeaderView.backgroundColor = [UIColor darkGrayColor];
    
    self.accountTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.accountTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.accountTableView.delegate = self.tableViewDelegate;
    self.accountTableView.dataSource = self.tableViewDelegate;
    
    _accountPickerHeaderView = [[UIView alloc] initForAutoLayout];
    self.accountPickerHeaderView.backgroundColor = [UIColor lightGrayColor];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapHeaderView:)];
    [self.accountPickerHeaderView addGestureRecognizer:tapGestureRecognizer];
    
    _accountPickkerHeaderLabel = [[UILabel alloc] initForAutoLayout];
    _accountPickkerHeaderLabel.text = @"Use My Own Account";
    
    _accountPickerHeaderImageView = [[UIImageView alloc] initForAutoLayout];
    
    [self.accountPickerHeaderView addSubview:self.accountPickkerHeaderLabel];
    [self.accountPickerHeaderView addSubview:self.accountPickerHeaderImageView];
    
    [self.view addSubview:self.chatsecureLabel];
    [self.view addSubview:self.stayConnectedLabel];
    [self.view addSubview:self.createLabel];
    [self.view addSubview:self.anonymousLabel];
    [self.view addSubview:self.createView];
    [self.view addSubview:self.anonymousView];
    [self.view addSubview:self.accountTableView];
    [self.view addSubview:self.accountPickerHeaderView];
    [self.view addSubview:self.accountTableView];
    
    [self addBaseConstraints];
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.accountTableView.contentSize.height <= self.accountTableView.frame.size.height) {
        self.accountTableView.scrollEnabled = NO;
    }
    else {
        self.accountTableView.scrollEnabled = YES;
    }
}

- (void)addBaseConstraints
{
    [self.chatsecureLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [self.chatsecureLabel autoConstrainAttribute:ALAttributeHorizontal toAttribute:ALAttributeHorizontal ofView:self.view withMultiplier:0.5];
    
    [self.stayConnectedLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.chatsecureLabel withOffset:10];
    [self.stayConnectedLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    [self.createView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.stayConnectedLabel withOffset:10];
    [self.createView autoConstrainAttribute:ALAttributeVertical toAttribute:ALAttributeVertical ofView:self.view withMultiplier:0.5];
    [self.createView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:0.25];
    [self.createView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.createView];
    
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
    
    ////// Account picker //////
    [self.accountPickerHeaderView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
    [self.accountPickerHeaderView autoSetDimension:ALDimensionHeight toSize:33];
    self.accountPickerBottomLayotuConstraint = [self.accountPickerHeaderView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
    
    [self.accountPickkerHeaderLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.accountPickkerHeaderLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
    
    [self.accountPickerHeaderImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(10, 10, 10, 10) excludingEdge:ALEdgeLeading];
    
    [self.accountTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.accountPickerHeaderView];
    [self.accountTableView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.accountPickerHeaderView];
    [self.accountTableView autoSetDimension:ALDimensionHeight toSize:self.tableViewHeight];
}

- (void)didTapHeaderView:(id)sender
{
    if (self.accountPickerBottomLayotuConstraint.constant == 0) {
        self.accountPickerBottomLayotuConstraint.constant = -1 * self.tableViewHeight;
    } else {
        self.accountPickerBottomLayotuConstraint.constant = 0;
    }
    
    [self.view setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
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

- (NSArray *)defaultAccountArray
{
    NSMutableArray *accountArray = [NSMutableArray array];
    __weak typeof(self)weakSelf = self;
    
    void (^successBlock)(void) = ^void(void) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (strongSelf.successBlock) {
            strongSelf.successBlock();
        }
    };
    
    
    [accountArray addObject:[OTRWelcomeAccountInfo accountInfoWithText:@"ChatSecure ID" image:nil didSelectBlock:NULL]];
    [accountArray addObject:[OTRWelcomeAccountInfo accountInfoWithText:@"XMPP" image:[UIImage imageNamed:@"xmpp"] didSelectBlock:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        OTRXMPPAccount *xmppAccount = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeJabber];
        OTRBaseLoginViewController *loginViewController = [[OTRBaseLoginViewController alloc] initWithForm:[OTRXLFormCreator formForAccount:xmppAccount] style:UITableViewStyleGrouped];
        loginViewController.successBlock = successBlock;
        loginViewController.account = xmppAccount;
        OTRXMPPLoginHandler *loginHandler = [[OTRXMPPLoginHandler alloc] init];
        loginViewController.createLoginHandler = loginHandler;
        
        [strongSelf.navigationController pushViewController:loginViewController animated:YES];
    }]];
    [accountArray addObject:[OTRWelcomeAccountInfo accountInfoWithText:@"Google" image:[UIImage imageNamed:@"gtalk"] didSelectBlock:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        
        //Authenicate and go through google oauth
        GTMOAuth2ViewControllerTouch * oauthViewController = [GTMOAuth2ViewControllerTouch controllerWithScope:GOOGLE_APP_SCOPE clientID:GOOGLE_APP_ID clientSecret:kOTRGoogleAppSecret keychainItemName:nil completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
            if (!error) {
                OTRGoogleOAuthXMPPAccount *googleAccount = [[OTRGoogleOAuthXMPPAccount alloc] initWithAccountType:OTRAccountTypeGoogleTalk];
                googleAccount.username = auth.userEmail;
                
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [googleAccount saveWithTransaction:transaction];
                }];
                
                googleAccount.oAuthTokenDictionary = auth.parameters;
                
                OTRBaseLoginViewController *loginViewController = [[OTRBaseLoginViewController alloc] initWithForm:[OTRXLFormCreator formForAccount:googleAccount] style:UITableViewStyleGrouped];
                loginViewController.successBlock = successBlock;
                loginViewController.account = googleAccount;
                OTRGoolgeOAuthLoginHandler *loginHandler = [[OTRGoolgeOAuthLoginHandler alloc] init];
                loginViewController.createLoginHandler = loginHandler;
                
                NSMutableArray *viewControllers = [strongSelf.navigationController.viewControllers mutableCopy];
                [viewControllers removeObject:viewController];
                [viewControllers addObject:loginViewController];
                [self.navigationController setViewControllers:viewControllers animated:YES];
            }
        }];
        [oauthViewController setPopViewBlock:^{
            
        }];
        [self.navigationController pushViewController:oauthViewController animated:YES];
    }]];
    
    return accountArray;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}
@end
