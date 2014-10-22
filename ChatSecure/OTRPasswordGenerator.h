//
//  OTRPasswordGenerator.h
//  ChatSecure
//
//  Created by David Chiles on 10/21/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRPasswordGenerator : NSObject

+ (NSString *)passwordWithLength:(NSUInteger)length;

@end
