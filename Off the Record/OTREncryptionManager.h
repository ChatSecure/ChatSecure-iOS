//
//  OTREncryptionManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRKit.h"

@interface OTREncryptionManager : NSObject <OTRKitDelegate>

+ (void) protectFileWithPath:(NSString*)path;

@end
