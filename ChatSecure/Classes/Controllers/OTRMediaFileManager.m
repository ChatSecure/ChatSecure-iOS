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
#import "OTRFileCopier.h"

NSString *const kOTRRootMediaDirectory = @"media";

@interface OTRMediaFileManager ()

@property (nonatomic) dispatch_queue_t concurrentQueue;
@property (nonatomic) dispatch_queue_t isolationQueue;
@property (nonatomic, strong) NSMutableDictionary *fileCopierDictionary;

@end

@implementation OTRMediaFileManager

- (instancetype)init
{
    if (self = [super init]) {
        self.fileCopierDictionary = [[NSMutableDictionary alloc] init];
        self.concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        NSString *isolationLabel = [NSString stringWithFormat:@"%@.isolation.%p", [self class], self];
        self.isolationQueue = dispatch_queue_create([isolationLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)setFileCopier:(OTRFileCopier *)fileCopier forEncryptedFilePath:(NSString *)encryptedFilePath
{
    if (encryptedFilePath) {
        dispatch_barrier_async(self.isolationQueue, ^{
            if (fileCopier) {
                [self.fileCopierDictionary setObject:fileCopier forKey:encryptedFilePath];
            } else {
                [self.fileCopierDictionary removeObjectForKey:encryptedFilePath];
            }
            
        });
    }
}

- (OTRFileCopier *)completionBlockForFileCopier:(OTRFileCopier *)fileCopier
{
    __block void (^completion)(NSInteger, NSError *) = nil;
    if (fileCopier) {
        dispatch_sync(self.isolationQueue, ^{
            completion = [self.fileCopierDictionary objectForKey:fileCopier];
        });
    }
    return completion;
}

#pragma - mark Public Methods

- (void)setupWithPath:(NSString *)path password:(NSString *)password
{
    _ioCipher = [[IOCipher alloc] initWithPath:path password:password];
}

- (void)copyDataFromFilePath:(NSString *)filePath toEncryptedPath:(NSString *)path completionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSInteger, NSError *))completion 
{
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.concurrentQueue, ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        __block OTRFileCopier *fileCopier = [[OTRFileCopier alloc] initWithFilePath:filePath toEncryptedPath:path ioCipher:strongSelf.ioCipher completionQueue:self.concurrentQueue completion:^(NSInteger bytesWritten, NSError *error) {
            
            if (completion) {
                dispatch_async([[self class] completionQueue:completionQueue], ^{
                    completion(bytesWritten,error);
                });
                
            }
            
            [strongSelf setFileCopier:nil forEncryptedFilePath:fileCopier.encryptedFilePath];
        }];
        [self setFileCopier:fileCopier forEncryptedFilePath:fileCopier.encryptedFilePath];
        [fileCopier start];
    });
    
}

- (void)setData:(NSData *)data forItem:(OTRMediaItem *)mediaItem completion:(void (^)(NSInteger bytesWritten, NSError *error))completion completionQueue:(dispatch_queue_t)completionQueue
{
    
    dispatch_async(self.concurrentQueue, ^{
        NSString *path = [[self class] pathForMediaItem:mediaItem];
        if (![path length]) {
            NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:150 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file path"}];
            dispatch_async([[self class] completionQueue:completionQueue], ^{
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
                dispatch_async(completion, ^{
                    completion(-1,error);
                });
                return;
            }
        }
        
        NSError *error = nil;
        BOOL created = [self.ioCipher createFileAtPath:path error:&error];
        if (!created) {
            NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:152 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file"}];
            dispatch_async(completion, ^{
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
    completionQueue = [[self class] completionQueue:completionQueue];
    
    dispatch_async(self.concurrentQueue, ^{
        NSString *filePath = [[self class] pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId];
        if (!filePath) {
            NSError *error = [NSError errorWithDomain:kOTRErrorDomain code:150 userInfo:@{NSLocalizedDescriptionKey:@"Unable to create file path"}];
            dispatch_async(completion, ^{
                completion(nil,error);
            });
            return;
        }
        
        BOOL fileExists = [self.ioCipher fileExistsAtPath:filePath isDirectory:nil];
        
        if (fileExists) {
            __block NSError *error;
            NSDictionary *fileAttributes = [self.ioCipher fileAttributesAtPath:filePath error:&error];
            if (error) {
                dispatch_async(completion, ^{
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

+ (dispatch_queue_t)completionQueue:(dispatch_queue_t)completionQueue
{
    if (!completionQueue) {
        return dispatch_get_main_queue();
    }
    
    return completionQueue;
}

+ (NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem buddyUniqueId:(NSString *)buddyUniqueId
{
    if ([buddyUniqueId length] && [mediaItem.uniqueId length] && [mediaItem.filename length]) {
        return [NSString pathWithComponents:@[@"/",kOTRRootMediaDirectory,buddyUniqueId,mediaItem.uniqueId,mediaItem.filename]];
    }
    return nil;
}

+ (NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem
{
    NSString *path = nil;
    NSString *buddyUniqueId = [self buddyUniqueIdForMeidaItem:mediaItem];
    return [self pathForMediaItem:mediaItem buddyUniqueId:buddyUniqueId];
}

+ (NSString *)buddyUniqueIdForMeidaItem:(OTRMediaItem *)mediaItem
{
    __block NSString *buddyUniqueId = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRMessage *message = [mediaItem parentMessageInTransaction:transaction];
        buddyUniqueId = [message buddyUniqueId];
    }];
    return buddyUniqueId;
}

@end
