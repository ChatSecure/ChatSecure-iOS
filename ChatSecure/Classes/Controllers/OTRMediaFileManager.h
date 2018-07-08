//
//  OTRMediaFileManager.h
//  ChatSecure
//
//  Created by David Chiles on 2/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;

@class OTRMediaItem, IOCipher;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const kOTRRootMediaDirectory;

@interface OTRMediaFileManager : NSObject

@property (nonatomic, strong, readonly) IOCipher *ioCipher;

- (BOOL)setupWithPath:(NSString *)path password:(NSString *)password;

- (void)copyDataFromFilePath:(NSString *)filePath
             toEncryptedPath:(NSString *)path
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion
             completionQueue:(nullable dispatch_queue_t)completionQueue;

- (void)setData:(NSData *)data
        forItem:(OTRMediaItem *)mediaItem
  buddyUniqueId:(NSString *)buddyUniqueId
     completion:(void (^)(NSInteger bytesWritten, NSError * _Nullable error))completion
completionQueue:(nullable dispatch_queue_t)completionQueue;

//#865
- (void)deleteDataForItem:(OTRMediaItem *)mediaItem
            buddyUniqueId:(NSString *)buddyUniqueId
               completion:(void (^)(BOOL success, NSError * _Nullable error))completion
          completionQueue:(nullable dispatch_queue_t)completionQueue;

- (nullable NSData*)dataForItem:(OTRMediaItem *)mediaItem
                  buddyUniqueId:(NSString *)buddyUniqueId
                          error:(NSError* __autoreleasing *)error;
- (nullable NSNumber*)dataLengthForItem:(OTRMediaItem *)mediaItem
                  buddyUniqueId:(NSString *)buddyUniqueId
                          error:(NSError* __autoreleasing *)error;

+ (nullable NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId;
+ (nullable NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId withLeadingSlash:(BOOL)includeLeadingSlash;

@property (class, nonatomic, readonly) OTRMediaFileManager *shared;

+ (instancetype)sharedInstance;

@end
NS_ASSUME_NONNULL_END
