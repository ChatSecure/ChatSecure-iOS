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
#import "OTRPushAPIClient.h"

#define REQUEST_PRODUCT_IDENTIFIERS @"request_product_identifiers"
#define PRODUCT_IDENTIFIERS_KEY @"identifiers"

#define PRODUCTS_KEY @"products"

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
    NSURL *requestURL = [NSURL URLWithString:REQUEST_PRODUCT_IDENTIFIERS relativeToURL:[OTRPushAPIClient sharedClient].baseURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:requestURL.absoluteString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [self fetchProductsWithIdentifiers:[NSSet setWithArray:[responseObject objectForKey:PRODUCT_IDENTIFIERS_KEY]]];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Error loading product identifiers: %@%@", [error localizedDescription], [error userInfo]);
    }];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:PAYMENTS_SETUP_ERROR_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSLog(@"Transaction: %@", transaction.transactionIdentifier);
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"Transaction purchased");
                //[[OTRPushController sharedInstance] registerWithReceipt:transaction.transactionReceipt resetAccount:NO];
                [self setProductIdentifier:transaction.payment.productIdentifier purchased:YES];
                [self sendProductUpdateNotification];
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"Transaction failed");
                [self sendProductUpdateNotification];
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Original transaction restored: %@", transaction.originalTransaction.transactionIdentifier);
                //[[OTRPushController sharedInstance] registerWithReceipt:transaction.transactionReceipt resetAccount:YES];
                [self setProductIdentifier:transaction.payment.productIdentifier purchased:YES];
                [self sendProductUpdateNotification];
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

- (void) sendProductUpdateNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRPurchaseControllerProductUpdateNotification object:self];
}

- (BOOL) isProductIdentifierPurchased:(NSString*)productIdentifier {
    NSMutableDictionary *productsDictionary = [self productsDictionary];
    NSNumber *productValue = [productsDictionary objectForKey:productIdentifier];
    if (!productValue) {
        return NO;
    }
    return [productValue boolValue];
}

- (NSMutableDictionary*) productsDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *productDictionary = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:PRODUCTS_KEY]];
    if (!productDictionary) {
        productDictionary = [NSMutableDictionary dictionary];
    }
    return productDictionary;
}

- (void) saveProductsDictionary:(NSMutableDictionary*)productsDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:productsDictionary forKey:PRODUCTS_KEY];
    BOOL success = [defaults synchronize];
    if (!success) {
        NSLog(@"Product preferences not saved to disk!");
    }
}


- (void) setProductIdentifier:(NSString*)productIdentifier purchased:(BOOL)purchased {
    NSMutableDictionary *productsDictionary = [self productsDictionary];
    [productsDictionary setObject:[NSNumber numberWithBool:purchased] forKey:productIdentifier];
    [self saveProductsDictionary:productsDictionary];
}

- (void) restorePurchases {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

@end
