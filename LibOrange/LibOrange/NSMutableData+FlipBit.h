//
//  NSMutableData+FlipBit.h
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "flipbit.h"

@interface NSMutableData (FlipBit) 

- (void)appendNetworkOrderUInt16:(UInt16)nonNetworkOrder;
- (void)appendNetworkOrderUInt32:(UInt32)nonNetworkOrder;
- (void)appendString:(NSString *)string paddToLen:(int)len;

@end
