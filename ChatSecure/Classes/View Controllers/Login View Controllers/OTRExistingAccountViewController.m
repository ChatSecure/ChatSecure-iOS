//
//  OTRAdvancedWelcomeViewController.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 7/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRExistingAccountViewController.h"
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
#import "OTRWelcomeAccountTableViewDelegate.h"

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
    
    [accountArray addObject:[OTRWelcomeAccountInfo accountInfoWithText:@"XMPP" image:[UIImage imageNamed:@"xmpp"] didSelectBlock:^{
        OTRXMPPAccount *xmppAccount = [[OTRXMPPAccount alloc] initWithAccountType:OTRAccountTypeJabber];
        OTRBaseLoginViewController *loginViewController = [OTRBaseLoginViewController loginViewControllerForAccount:xmppAccount];
        loginViewController.completionBlock = self.completionBlock;
        loginViewController.account = xmppAccount;
        [self.navigationController pushViewController:loginViewController animated:YES];
    }]];
    [accountArray addObject:[OTRWelcomeAccountInfo accountInfoWithText:@"Google" image:[UIImage imageNamed:@"gtalk"] didSelectBlock:^{
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
                loginViewController.completionBlock = self.completionBlock;
                loginViewController.account = googleAccount;
                OTRGoolgeOAuthLoginHandler *loginHandler = [[OTRGoolgeOAuthLoginHandler alloc] init];
                loginViewController.createLoginHandler = loginHandler;
                
                NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
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

@end
