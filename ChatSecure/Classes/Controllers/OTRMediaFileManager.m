//
//  OTRMediaFileManager.m
//  ChatSecure
//
//  Created by David Chiles on 2/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaFileManager.h"
#import "IOCipher.h"
#import "OTRMediaItem.h"
#import "OTRMessage.h"
#import "OTRDatabaseManager.h"
#import "OTRConstants.h"

NSString *const kOTRRootMediaDirectory = @"media";

@interface OTRMediaFileManager ()

@property (nonatomic) dispatch_queue_t concurrentQueue;

@end

@implementation OTRMediaFileManager

- (instancetype)init
{
    if (self = [super init]) {
        self.concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

#pragma - mark Public Methods

- (BOOL)setupWithPath:(NSString *)path password:(NSString *)password
{
    _ioCipher = [[IOCipher alloc] initWithPath:path password:password];
    return _ioCipher != nil;
}

- (void)copyDataFromFilePath:(NSString *)filePath toEncryptedPath:(NSString *)path completionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSError *))completion
{
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.concurrentQueue, ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        NSError *error = nil;
        [strongSelf.ioCipher copyItemAtFileSystemPath:filePath toEncryptedPath:path error:&error];
        
        if (completion) {
            dispatch_async(completionQueue, ^{
                completion(error);
            });
        }
    });
    
}

- (void)setData:(NSData *)data forItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId completion:(void (^)(NSInteger bytesWritten, NSError *error))completion completionQueue:(dispatch_queue_t)completionQueue
{
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }

    
    dispatch_async(self.concurrentQueue, ^{
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
        
    });
    
}
- (void)dataForItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId completion:(void (^)(NSData *, NSError *))completion completionQueue:(dispatch_queue_t)completionQueue
{
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    dispatch_async(self.concurrentQueue, ^{
        NSString *filePath = [[self class] pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId];
        if (!filePath) {
            NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:150 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file path"}];
            dispatch_async(completionQueue, ^{
                completion(nil,error);
            });
            return;
        }
        
        BOOL fileExists = [self.ioCipher fileExistsAtPath:filePath isDirectory:nil];
        
        if (fileExists) {
            __block NSError *error;
            NSDictionary *fileAttributes = [self.ioCipher fileAttributesAtPath:filePath error:&error];
            if (error) {
                dispatch_async(completionQueue, ^{
                    completion(nil,error);
                });
                return;
            }
            
            NSNumber *length = fileAttributes[NSFileSize];
            
            NSData *data = [self.ioCipher readDataFromFileAtPath:filePath length:[length integerValue] offset:0 error:&error];
            
            dispatch_async(completionQueue, ^{
                completion(data,error);
            });
        }
    });
}

#pragma - mark Class Methods

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
    if ([buddyUniqueId length] && [mediaItem.uniqueId length] && [mediaItem.filename length]) {
        return [NSString pathWithComponents:@[@"/",kOTRRootMediaDirectory,buddyUniqueId,mediaItem.uniqueId,mediaItem.filename]];
    }
    return nil;
}

@end
