//
//  OTRStoreViewController.m
//  Off the Record
//
//  Created by Christopher Ballinger on 9/28/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRStoreViewController.h"
#import "MBProgressHUD.h"
#import "AFNetworking.h"
#import "Strings.h"

#define SERVER_URL @"http://127.0.0.1:5000/" 
#define REQUEST_PRODUCT_IDENTIFIERS @"request_product_identifiers"
#define PRODUCT_IDENTIFIERS_KEY @"identifiers"

@interface OTRStoreViewController ()

@end

@implementation OTRStoreViewController
@synthesize productIdentifiers, productTableView;

- (id)init {
    if(self = [super init]) {
        self.productTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.productTableView.delegate = self;
        self.productTableView.dataSource = self;
        self.title = STORE_STRING;
    }
    return self;
}

- (void) loadView {
    [super loadView];
	[self.view addSubview:productTableView];
}

- (void) requestProductIdentifiers {
    // Code to request product identifiers here
    NSURLRequest *productsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[SERVER_URL stringByAppendingString:REQUEST_PRODUCT_IDENTIFIERS]]];
    AFJSONRequestOperation *request = [AFJSONRequestOperation JSONRequestOperationWithRequest:productsRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.productIdentifiers = [JSON objectForKey:PRODUCT_IDENTIFIERS_KEY];
        [self hideHUD];
        [productTableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error loading product identifiers: %@%@", [error localizedDescription], [error userInfo]);
        [self hideHUD];
    }];
    [request start];
}

- (void) hideHUD {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

     

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.productTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.productTableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self requestProductIdentifiers];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [productIdentifiers objectAtIndex:indexPath.row];
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [productIdentifiers count];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
