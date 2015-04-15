//
//  OTRMediaFileManager.h
//  ChatSecure
//
//  Created by David Chiles on 2/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTRMediaItem, IOCipher;

extern NSString *const kOTRRootMediaDirectory;

@interface OTRMediaFileManager : NSObject

@property (nonatomic, strong, readonly) IOCipher *ioCipher;

- (BOOL)setupWithPath:(NSString *)path password:(NSString *)password;

- (void)copyDataFromFilePath:(NSString *)filePath
             toEncryptedPath:(NSString *)path
             completionQueue:(dispatch_queue_t)completionQueue
                  completion:(void (^)(NSError *))completion;

- (void)setData:(NSData *)data
        forItem:(OTRMediaItem *)mediaItem
  buddyUniqueId:(NSString *)buddyUniqueId
     completion:(void (^)(NSInteger bytesWritten, NSError *error))completion
completionQueue:(dispatch_queue_t)completionQueue;

- (void)dataForItem:(OTRMediaItem *)mediaItem
      buddyUniqueId:(NSString *)buddyUniqueId
          completion:(void (^)(NSData *data, NSError *error))completion
     completionQueue:(dispatch_queue_t)completionQueue;

+ (NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId;

+ (instancetype)sharedInstance;

@end
