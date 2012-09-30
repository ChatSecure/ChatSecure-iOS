//
//  OTRPurchaseController.m
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

#import "OTRPurchaseController.h"
#import "AFNetworking.h"
#import "Strings.h"
#import "OTRPushController.h"

#define REQUEST_PRODUCT_IDENTIFIERS @"request_product_identifiers"
#define PRODUCT_IDENTIFIERS_KEY @"identifiers"

@implementation OTRPurchaseController
@synthesize products;

- (void) dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (id) init {
    if (self = [super init]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

+ (OTRPurchaseController*)sharedInstance
{
    static dispatch_once_t once;
    static OTRPurchaseController *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[OTRPurchaseController alloc] init];
    });
    return sharedInstance;
}

- (void) requestProducts {
    if (products) {
        [self.delegate productsUpdated:products];
    } else {
        [self requestProductIdentifiers];
    }
}

- (void) requestProductIdentifiers {
    // Code to request product identifiers here
    NSURLRequest *productsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:REQUEST_PRODUCT_IDENTIFIERS relativeToURL:[OTRPushController baseURL]]];
    AFJSONRequestOperation *request = [AFJSONRequestOperation JSONRequestOperationWithRequest:productsRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        [self fetchProductsWithIdentifiers:[NSSet setWithArray:[JSON objectForKey:PRODUCT_IDENTIFIERS_KEY]]];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Error loading product identifiers: %@%@", [error localizedDescription], [error userInfo]);
    }];
    [request start];
}

- (void) fetchProductsWithIdentifiers:(NSSet*)identifiers {
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
    request.delegate = self;
    [request start];
}


- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if ([response.invalidProductIdentifiers count] > 0) {
        NSLog(@"Invalid products identifiers: %@", [response.invalidProductIdentifiers description]);
    }
    self.products = response.products;
    [self.delegate productsUpdated:products];
}

- (void) buyProduct:(SKProduct *)product {
    if ([SKPaymentQueue canMakePayments]) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:CANT_MAKE_PAYMENTS_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSLog(@"Transaction: %@", transaction.transactionIdentifier);
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"Transaction purchased");
                [[OTRPushController sharedInstance] registerWithReceipt:transaction.transactionReceipt transactionIdentifier:transaction.transactionIdentifier];
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"Transaction failed");
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Original transaction restored: %@", transaction.originalTransaction.transactionIdentifier);
                [[OTRPushController sharedInstance] registerWithReceipt:transaction.transactionReceipt transactionIdentifier:transaction.originalTransaction.transactionIdentifier];
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction]; 
                NSLog(@"Transaction restored");
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Purchasing transaction... ");
                break;
            default:
                break;
        }
    }
}

- (void) restorePurchases {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end
