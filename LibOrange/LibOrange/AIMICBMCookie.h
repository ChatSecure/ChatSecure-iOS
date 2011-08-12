//
//  AIMICBMClient.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AIMICBMCookie : NSObject {
    char cookieData[8];
}

- (id)initWithCookieData:(const char *)theCookieData;
- (NSData *)cookieData;

+ (AIMICBMCookie *)randomCookie;
- (BOOL)isEqualToCookie:(AIMICBMCookie *)otherCookie;

@end
