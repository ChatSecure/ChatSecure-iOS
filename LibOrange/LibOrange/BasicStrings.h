/*
 *  BasicStrings.h
 *  TalkToOscar
 *
 *  Created by Alex Nichol on 3/23/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import "flipbit.h"
#import <Foundation/Foundation.h>

NSString * decodeString8 (NSData * string8Data);
NSString * decodeString16 (NSData * string16Data);
NSData * encodeString8 (NSString * string);
NSData * encodeString16 (NSString * string);
NSArray * decodeString8Array (NSData * string8Arr);
