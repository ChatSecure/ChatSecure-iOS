//
//  OTRMediaServer.h
//  ChatSecure
//
//  Created by David Chiles on 2/24/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;

@class OTRMediaItem;

@interface OTRMediaServer : NSObject

- (BOOL)startOnPort:(NSUInteger)port error:(NSError **)error;

- (NSURL *)urlForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId;

+ (instancetype)sharedInstance;

@end
