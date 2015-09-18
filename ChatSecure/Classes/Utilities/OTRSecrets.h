//
//  OTRSecrets.h
//  Off the Record
//
//  Created by Chris Ballinger on 12/9/11.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

@import Foundation;

@interface OTRSecrets : NSObject

+ (NSString*) googleAppSecret;
+ (NSString*) hockeyLiveIdentifier;
+ (NSString*) hockeyBetaIdentifier;

@end