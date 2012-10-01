//
//  OTRStoreTableViewCell.m
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

#import "OTRStoreTableViewCell.h"
#import "OTRPurchaseController.h"
#import "Strings.h"

@implementation OTRStoreTableViewCell
@synthesize product;

- (void) setProduct:(SKProduct *)newProduct {
    product = newProduct;
    self.textLabel.text = product.localizedTitle;
    self.detailTextLabel.text = product.localizedDescription;
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:product.priceLocale];
    NSString *priceString = [numberFormatter stringFromNumber:product.price];
    
    BOOL productPurchased = [[OTRPurchaseController sharedInstance] isProductIdentifierPurchased:product.productIdentifier];
    if (productPurchased) {
        priceString = PURCHASED_STRING;
    }
    
    UISegmentedControl *buyButton = [[UISegmentedControl alloc]initWithItems:@[priceString]];
    buyButton.segmentedControlStyle = UISegmentedControlStyleBar;
    buyButton.momentary = YES;
    if (productPurchased) {
        buyButton.enabled = NO;
    } else {
        [buyButton addTarget:self
                      action:@selector(buyButtonPressed:)
            forControlEvents:UIControlEventValueChanged];
    }
    self.accessoryView = buyButton;
}

- (void) buyButtonPressed:(id)sender {
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    self.accessoryView = activityView;
    [[OTRPurchaseController sharedInstance] buyProduct:self.product];
}

@end
