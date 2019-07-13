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
    
    return accountArray;
}

@end
