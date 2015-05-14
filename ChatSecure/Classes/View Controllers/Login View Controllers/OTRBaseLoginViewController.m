//
//  OTRBaseLoginViewController.m
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBaseLoginViewController.h"
#import "Strings.h"

@interface OTRBaseLoginViewController ()

@end

@implementation OTRBaseLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loginCreateButtonItem = [[UIBarButtonItem alloc] initWithTitle:LOGIN_STRING style:UIBarButtonItemStylePlain target:self action:@selector(LoginButtonPressed:)];
    
    self.navigationItem.rightBarButtonItem = self.loginCreateButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)LoginButtonPressed:(id)sender
{
    if ([self validForm]) {
        [self.createLoginHandler performActionWithValidForm:self.form account:self.account completion:^(NSError *error, OTRAccount *account) {
            
            if (account) {
                self.account = account;
            }
            
            if (error) {
                [self handleError:error];
            }
        }];
    }
}

- (BOOL)validForm
{
    BOOL validForm = YES;
    NSArray *formValidationErrors = [self formValidationErrors];
    if ([formValidationErrors count]) {
        validForm = NO;
    }
    
    [formValidationErrors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        XLFormValidationStatus * validationStatus = [[obj userInfo] objectForKey:XLValidationStatusErrorKey];
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[self.form indexPathOfFormRow:validationStatus.rowDescriptor]];
        cell.backgroundColor = [UIColor orangeColor];
        [UIView animateWithDuration:0.3 animations:^{
            cell.backgroundColor = [UIColor whiteColor];
        }];
        
    }];
    return validForm;
}

- (void)handleError:(NSError *)error
{
    //show xmpp erors, cert errors, tor errors, oauth errors.
    
}

@end
