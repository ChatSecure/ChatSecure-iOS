//
//  AIMFeedbag+Search.h
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"

@interface AIMFeedbag (Search)

- (AIMFeedbagItem *)findRootGroup;
- (AIMFeedbagItem *)findPDMode;
- (AIMFeedbagItem *)denyWithUsername:(NSString *)username;
- (AIMFeedbagItem *)permitWithUsername:(NSString *)username;

@end
