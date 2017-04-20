//
//  OTRAdvancedWelcomeViewController.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRExistingAccountViewController.h"
#import "OTRCircleView.h"
#import "OTRWelcomeAccountTableViewDelegate.h"
#import "OTRImages.h"
#import "OTRBaseLoginViewController.h"
#import "OTRXLFormCreator.h"
#import "OTRXMPPLoginHandler.h"
#import "OTRXMPPCreateAccountHandler.h"
#import "OTRGoogleOAuthXMPPAccount.h"
#import "OTRGoolgeOAuthLoginHandler.h"
@import gtm_oauth2;
#import "OTRDatabaseManager.h"
#import "OTRWelcomeAccountTableViewDelegate.h"
@import OTRAssets;
@import PureLayout;

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

@interface OTRExistingAccountViewController ()
@property (nonatomic, strong, readonly) OTRWelcomeAccountTableViewDelegate *tableDelegate;
@end

@implementation OTRExistingAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableDelegate = [[OTRWelcomeAccountTableViewDelegate alloc] init];
    self.tableDelegate.welcomeAccountInfoArray = self.accountInfoArray;
    self.tableView.delegate = self.tableDelegate;
    self.tableView.dataSource = self.tableDelegate;
    self.tableView.rowHeight = 80;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _accountInfoArray = [self defaultAccountArray];
    }
    return self;
}

- (instancetype) initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        _accountInfoArray = [self defaultAccountArray];
    }
    return self;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _accountInfoArray = [self defaultAccountArray];
    }
    return self;
}

- (instancetype) init
{
    if (self = [self initWithAccountInfoArray:[self defaultAccountArray]]) {
    }
    return self;
}

- (instancetype) initWithAccountInfoArray:(NSArray*)accountInfoArray {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _accountInfoArray = accountInfoArray;
    }
    return self;
}

- (NSArray *)defaultAccountArray
{
    NSMutableArray *accountArray = [NSMutableArray array];
    __weak __typeof__(self) weakSelf = self;
    
    [accountArray addObject:[OTRWelcomeAccountInfo accountInfoWithText:@"XMPP" image:[UIImage imageNamed:@"xmpp" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] didSelectBlock:^{
        __typeof__(self) strongSelf = weakSelf;
		OTRBaseLoginViewController *loginViewController = [[OTRBaseLoginViewController alloc] init];
        loginViewController.form = [XLFormDescriptor existingAccountFormWithAccountType:OTRAccountTypeJabber];
        loginViewController.loginHandler = [[OTRXMPPLoginHandler alloc] init];
        [strongSelf.navigationController pushViewController:loginViewController animated:YES];
    }]];
    
    [accountArray addObject:[OTRWelcomeAccountInfo accountInfoWithText:@"Google" image:[UIImage imageNamed:@"gtalk" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil] didSelectBlock:^{
        __typeof__(self) strongSelf = weakSelf;
        //Authenicate and go through google oauth
        GTMOAuth2ViewControllerTouch * oauthViewController = [GTMOAuth2ViewControllerTouch controllerWithScope:[OTRBranding googleAppScope] clientID:[OTRBranding googleAppId] clientSecret:[OTRSecrets googleAppSecret] keychainItemName:nil completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
            if (!error) {
                OTRGoogleOAuthXMPPAccount *googleAccount = [[OTRGoogleOAuthXMPPAccount alloc] initWithUsername:auth.userEmail accountType:OTRAccountTypeGoogleTalk];
                googleAccount.oAuthTokenDictionary = auth.parameters;
                
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [googleAccount saveWithTransaction:transaction];
                }];
                
                OTRBaseLoginViewController *loginViewController = [[OTRBaseLoginViewController alloc] initWithAccount:googleAccount];
                OTRGoolgeOAuthLoginHandler *loginHandler = [[OTRGoolgeOAuthLoginHandler alloc] init];
                loginViewController.loginHandler = loginHandler;
                
                NSMutableArray *viewControllers = [strongSelf.navigationController.viewControllers mutableCopy];
                [viewControllers removeObject:viewController];
                [viewControllers addObject:loginViewController];
                [strongSelf.navigationController setViewControllers:viewControllers animated:YES];
            }
        }];
        [oauthViewController setPopViewBlock:^{
            
        }];
        [strongSelf.navigationController pushViewController:oauthViewController animated:YES];
    }]];
    
    return accountArray;
}

@end
