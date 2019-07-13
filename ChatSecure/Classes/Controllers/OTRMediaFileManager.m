//
//  OTRMediaFileManager.m
//  ChatSecure
//
//  Created by David Chiles on 2/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaFileManager.h"
@import IOCipher;
#import "OTRMediaItem.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRDatabaseManager.h"
#import "OTRConstants.h"

NSString *const kOTRRootMediaDirectory = @"media";

@interface OTRMediaFileManager () {
    void *IsOnInternalQueueKey;
}

@property (nonatomic) dispatch_queue_t concurrentQueue;

/** Uses dispatch_barrier_async. Will perform block asynchronously on the internalQueue, unless we're already on internalQueue */
- (void) performAsyncWrite:(dispatch_block_t)block;

/** Uses dispatch_sync. Will perform block synchronously on the internalQueue and block for result if called on another queue. */
- (void) performSyncRead:(dispatch_block_t)block;

@end

@implementation OTRMediaFileManager

- (instancetype)init
{
    if (self = [super init]) {
        // We use dispatch_barrier_async with a concurrent queue to allow for multiple-read single-write.
        _concurrentQueue = dispatch_queue_create(NSStringFromClass(self.class).UTF8String, DISPATCH_QUEUE_CONCURRENT);
        
        // For safe usage of dispatch_sync
        IsOnInternalQueueKey = &IsOnInternalQueueKey;
        void *nonNullUnusedPointer = (__bridge void *)self;
        dispatch_queue_set_specific(_concurrentQueue, IsOnInternalQueueKey, nonNullUnusedPointer, NULL);
        
    }
    return self;
}

#pragma - mark Public Methods

- (BOOL)setupWithPath:(NSString *)path password:(NSString *)password
{
    _ioCipher = [[IOCipher alloc] initWithPath:path password:password];
    if (!_ioCipher) {
        return NO;
    }
    return [_ioCipher setCipherCompatibility:3];
}

- (void)copyDataFromFilePath:(NSString *)filePath
             toEncryptedPath:(NSString *)path
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion
             completionQueue:(nullable dispatch_queue_t)completionQueue
{
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    __weak typeof(self)weakSelf = self;
    [self performAsyncWrite:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        NSError *error = nil;
        BOOL result = [strongSelf.ioCipher copyItemAtFileSystemPath:filePath toEncryptedPath:path error:&error];
        
        if (completion) {
            dispatch_async(completionQueue, ^{
                completion(result, error);
            });
        }
    }];
}

- (void)setData:(NSData *)data
        forItem:(OTRMediaItem *)mediaItem
  buddyUniqueId:(NSString *)buddyUniqueId
     completion:(void (^)(NSInteger bytesWritten, NSError * _Nullable error))completion
completionQueue:(nullable dispatch_queue_t)completionQueue {
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    [self performAsyncWrite:^{
        NSString *path = [[self class] pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId];
        if (![path length]) {
            NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:150 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file path"}];
            dispatch_async(completionQueue, ^{
                completion(-1,error);
            });
            return;
        }
        
        BOOL fileExists = [self.ioCipher fileExistsAtPath:path isDirectory:NULL];
        
        if (fileExists) {
            NSError *error = nil;
            [self.ioCipher removeItemAtPath:path error:&error];
            if (error) {
                NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:151 userInfo:@{NSLocalizedDescriptionKey:@"Unable to remove existing file"}];
                dispatch_async(completionQueue, ^{
                    completion(-1,error);
                });
                return;
            }
        }
        
        NSError *error = nil;
        BOOL created = [self.ioCipher createFileAtPath:path error:&error];
        if (!created) {
            NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:152 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file"}];
            dispatch_async(completionQueue, ^{
                completion(-1,error);
            });
            return;
        }
        __block NSInteger written = [self.ioCipher writeDataToFileAtPath:path data:data offset:0 error:&error];
        
        dispatch_async(completionQueue, ^{
            completion(written, error);
        });

    }];
}

//#865
- (void)deleteDataForItem:(OTRMediaItem *)mediaItem
            buddyUniqueId:(NSString *)buddyUniqueId
               completion:(void (^)(BOOL success, NSError * _Nullable error))completion
          completionQueue:(nullable dispatch_queue_t)completionQueue {
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    [self performAsyncWrite:^{
        NSString *path = [[self class] pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId];
        if (![path length]) {
            NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:150 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file path"}];
            if (completion) {
                dispatch_async(completionQueue, ^{
                    completion(NO, error);
                });
            }
            return;
        }
        
        BOOL fileExists = [self.ioCipher fileExistsAtPath:path isDirectory:NULL];
        
        if (fileExists) {
            NSError *error = nil;
            [self.ioCipher removeItemAtPath:path error:&error];
            if (error) {
                NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:151 userInfo:@{NSLocalizedDescriptionKey:@"Unable to remove existing file"}];
                if (completion) {
                    dispatch_async(completionQueue, ^{
                        completion(NO, error);
                    });
                }
                return;
            }
        }
        
        if (completion) {
            dispatch_async(completionQueue, ^{
                completion(YES, nil);
            });
        }
    }];
}

/* Internal. If "length" is set, only return the length of the data, otherwise the data ifself */
- (nullable NSData*)dataForItem:(OTRMediaItem *)mediaItem
                  buddyUniqueId:(NSString *)buddyUniqueId
                          error:(NSError* __autoreleasing *)error
                         length:(NSNumber* __autoreleasing *)length {
    __block NSData *data = nil;
    __block NSNumber *dataLength = nil;
    [self performSyncRead:^{
        NSString *filePath = [[self class] pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId];
        if (!filePath) {
            if (error) {
                *error = [NSError errorWithDomain:kOTRErrorDomain code:150 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file path"}];
            }
            return;
        }
        BOOL fileExists = [self.ioCipher fileExistsAtPath:filePath isDirectory:nil];
        if (!fileExists) {
            if (error) {
                *error = [NSError errorWithDomain:kOTRErrorDomain code:151 userInfo:@{NSLocalizedDescriptionKey:@"File does not exist!"}];
            }
            return;
        }
        NSDictionary *fileAttributes = [self.ioCipher fileAttributesAtPath:filePath error:error];
        if (error && *error) {
            return;
        }
        if (length != nil) {
            dataLength = fileAttributes[NSFileSize];
        } else {
            NSNumber *length = fileAttributes[NSFileSize];
            data = [self.ioCipher readDataFromFileAtPath:filePath length:length.integerValue offset:0 error:error];
        }
    }];
    if (length != nil) {
        *length = dataLength;
    }
    return data;
}

- (nullable NSData*)dataForItem:(OTRMediaItem *)mediaItem
                  buddyUniqueId:(NSString *)buddyUniqueId
                          error:(NSError* __autoreleasing *)error {
    return [self dataForItem:mediaItem buddyUniqueId:buddyUniqueId error:error length:nil];
}

- (NSNumber *)dataLengthForItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId error:(NSError * _Nullable __autoreleasing *)error {
    NSNumber *length = nil;
    [self dataForItem:mediaItem buddyUniqueId:buddyUniqueId error:error length:&length];
    return length;
}

#pragma - mark Class Methods

+ (OTRMediaFileManager*) shared {
    return [self sharedInstance];
}

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId
{
    return [self pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId withLeadingSlash:YES];
}

+ (NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId withLeadingSlash:(BOOL)includeLeadingSlash
{
    if ([buddyUniqueId length] && [mediaItem.uniqueId length] && [mediaItem.filename length]) {
        NSString *path = [NSString pathWithComponents:@[kOTRRootMediaDirectory,buddyUniqueId,mediaItem.uniqueId,mediaItem.filename]];
        if (includeLeadingSlash) {
            return [NSString stringWithFormat:@"/%@",path];
        }
        return path;
    }
    return nil;
}

#pragma mark Utility

/** Will perform block synchronously on the internalQueue and block for result if called on another queue. */
- (void) performSyncRead:(dispatch_block_t)block {
    NSParameterAssert(block != nil);
    if (!block) { return; }
    if (dispatch_get_specific(IsOnInternalQueueKey)) {
        block();
    } else {
        dispatch_sync(_concurrentQueue, block);
    }
}

/** Will perform block asynchronously on the internalQueue, unless we're already on internalQueue */
- (void) performAsyncWrite:(dispatch_block_t)block {
    NSParameterAssert(block != nil);
    if (!block) { return; }
    if (dispatch_get_specific(IsOnInternalQueueKey)) {
        block();
    } else {
        dispatch_barrier_async(_concurrentQueue, block);
    }
}

@end
