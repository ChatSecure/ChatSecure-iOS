//
//  OTRStoreViewController.m
//  Off the Record
//
//  Created by Christopher Ballinger on 9/28/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRStoreViewController.h"
#import "MBProgressHUD.h"
#import "Strings.h"
#import "OTRPushAccessViewController.h"
#import "OTRConstants.h"

enum {
    ACCOUNT_INFO_SECTION = 0,
    PATS_SECTION,
    PRODUCTS_SECTION
};

enum {
    ACCOUNT_INFO_ACCOUNT_ROW = 0,
    ACCOUNT_INFO_PASSWORD_ROW,
    ACCOUNT_INFO_EXPIRATION_ROW
};

@interface OTRStoreViewController ()

@end

@implementation OTRStoreViewController
@synthesize productTableView, products, purchaseController, pushController;

- (void) dealloc {
    self.productTableView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if(self = [super init]) {
        self.productTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.productTableView.delegate = self;
        self.productTableView.dataSource = self;
        self.title = STORE_STRING;
        self.purchaseController = [OTRPurchaseController sharedInstance];
        self.pushController = [OTRPushController sharedInstance];
        purchaseController.delegate = self;
        self.products = [NSArray array];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:RESTORE_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(restorePurchases:)];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedProductUpdateNotification:) name:kOTRPurchaseControllerProductUpdateNotification object:purchaseController];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedProductUpdateNotification:) name:kOTRPushAccountUpdateNotification object:pushController];
    }
    return self;
}

- (void) receivedProductUpdateNotification:(NSNotification*)notification {
    [self.productTableView reloadData];
}

- (void) loadView {
    [super loadView];
	[self.view addSubview:productTableView];
}

- (void) hideHUD {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void) showHUD {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

- (void) restorePurchases:(id)sender {
    [purchaseController restorePurchases];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.productTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.productTableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self showHUD];
    [purchaseController requestProducts];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ACCOUNT_INFO_SECTION) {
        static NSString *cellIdentifier = @"InfoCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        if (indexPath.row == ACCOUNT_INFO_ACCOUNT_ROW) {
            cell.textLabel.text = ACCOUNT_ID_STRING;
            cell.detailTextLabel.text = pushController.accountID;
        } else if (indexPath.row == ACCOUNT_INFO_PASSWORD_ROW) {
            cell.textLabel.text = PASSWORD_STRING;
            cell.detailTextLabel.text = pushController.password;
        } else if (indexPath.row == ACCOUNT_INFO_EXPIRATION_ROW) {
            cell.textLabel.text = EXPIRATION_TITLE_STRING;
            cell.detailTextLabel.text = [pushController.expirationDate description];
        }
        return cell;
    }
    if (indexPath.section == PRODUCTS_SECTION) {
        static NSString *cellIdentifier = @"StoreCellIdentifier";
        OTRStoreTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[OTRStoreTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        SKProduct *product = [products objectAtIndex:indexPath.row];
        cell.product = product;
        return cell;
    }
    if (indexPath.section == PATS_SECTION) {
        static NSString *cellIdentifier = @"CellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        cell.textLabel.text = PATS_SECTION_STRING;
        return cell;
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == PATS_SECTION) {
        OTRPushAccessViewController *patViewController = [[OTRPushAccessViewController alloc] init];
        [self.navigationController pushViewController:patViewController animated:YES];
    }
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == ACCOUNT_INFO_SECTION) {
        return ACCOUNT_INFO_STRING;
    } else if (section == PRODUCTS_SECTION) {
        return PRODUCTS_SECTION_STRING;
    } else if (section == PATS_SECTION) {
        return PATS_SECTION_STRING;
    }
    return nil;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == ACCOUNT_INFO_SECTION) {
        return 3;
    } else if (section == PRODUCTS_SECTION) {
        return [products count];
    } else if (section == PATS_SECTION) {
        return 1;
    }
    return 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) productsUpdated:(NSArray*)newProducts {
    self.products = newProducts;
    [self hideHUD];
    [self.productTableView reloadData];
}

@end
