//
//  OTRMediaFileManager.h
//  ChatSecure
//
//  Created by David Chiles on 2/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTRMediaItem;

@interface OTRMediaFileManager : NSObject

- (void)setupWithPath:(NSString *)path password:(NSString *)password;

- (void)setData:(NSData *)data forItem:(OTRMediaItem *)mediaItem
     completion:(void (^)(NSInteger bytesWritten, NSError *error))completion
completionQueue:(dispatch_queue_t)completionQueue;

- (void)mediaForItem:(OTRMediaItem *)mediaItem
          completion:(void (^)(NSData *data, NSError *error))completion
     completionQueue:(dispatch_queue_t)completionQueue;

+ (instancetype)sharedInstance;

@end
