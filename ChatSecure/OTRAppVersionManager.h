//
//  OTRAppVersionManager.h
//  Off the Record
//
//  Created by David on 9/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRAppVersionManager : NSObject


+ (void)applyUpdatesForAppVersion:(NSString *)appVersionString;


+ (void)applyAppUpdatesForCurrentAppVersion;
+ (NSString *)currentAppVersionString;

@end
