//
//  OTRAssets.h
//  OTRAssets
//
//  Created by Christopher Ballinger on 9/15/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

@import UIKit;

/** Stub class for identifying asset framework bundle via bundleForClass: */
@interface OTRAssets : NSObject

/** Returns OTRResources.bundle */
+ (NSBundle*) resourcesBundle;

@end

//! Project version number for OTRAssets.
FOUNDATION_EXPORT double OTRAssetsVersionNumber;

//! Project version string for OTRAssets.
FOUNDATION_EXPORT const unsigned char OTRAssetsVersionString[];

FOUNDATION_EXPORT NSString *const kOTRDefaultLanguageLocale;
FOUNDATION_EXPORT NSString *const kOTRSettingKeyLanguage;

// In this header, you should import all the public headers of your framework using statements like #import <OTRAssets/PublicHeader.h>

#import "OTRStrings.h"
#import "OTRSecrets.h"
#import "OTRBranding.h"
#import "OTRLanguageManager.h"
