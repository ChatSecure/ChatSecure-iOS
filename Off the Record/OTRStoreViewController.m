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


@interface OTRStoreViewController ()

@end

@implementation OTRStoreViewController
@synthesize productTableView, products, purchaseController;

- (void) dealloc {
    self.productTableView = nil;
}

- (id)init {
    if(self = [super init]) {
        self.productTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.productTableView.delegate = self;
        self.productTableView.dataSource = self;
        self.title = STORE_STRING;
        self.purchaseController = [OTRPurchaseController sharedInstance];
        purchaseController.delegate = self;
        self.products = [NSArray array];
    }
    return self;
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

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.productTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.productTableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self showHUD];
    [purchaseController requestProducts];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CellIdentifier";
    OTRStoreTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[OTRStoreTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    SKProduct *product = [products objectAtIndex:indexPath.row];
    cell.product = product;
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [products count];
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
