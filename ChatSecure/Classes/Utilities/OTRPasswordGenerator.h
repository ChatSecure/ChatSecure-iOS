//
//  OTRPasswordGenerator.h
//  ChatSecure
//
//  Created by David Chiles on 10/21/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSUInteger const OTRDefaultPasswordLength;

@interface OTRPasswordGenerator : NSObject

/** Length is number of raw random bytes, which is then converted to base64 so expect a longer length. */
+ (NSString *)passwordWithLength:(NSUInteger)length;

@end
