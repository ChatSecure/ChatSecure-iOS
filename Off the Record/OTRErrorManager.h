//
//  OTRErrorManager.h
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRErrorManager : NSObject

+ (NSString *)errorStringWithSSLStatus:(OSStatus)status;

@end
