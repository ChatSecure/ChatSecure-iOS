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

NSString *const rootMediaDirectory = @"media";

@interface OTRMediaFileManager ()

@property (nonatomic) dispatch_queue_t concurrentQueue;
@property (nonatomic, strong) IOCipher *ioCipher;

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

- (void)setupWithPath:(NSString *)path password:(NSString *)password
{
    self.ioCipher = [[IOCipher alloc] initWithPath:path password:password];
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

- (void)mediaForItem:(OTRMediaItem *)mediaItem completion:(void (^)(NSData *, NSError *))completion completionQueue:(dispatch_queue_t)completionQueue
{
    completionQueue = [[self class] completionQueue:completionQueue];
    
    dispatch_async(self.concurrentQueue, ^{
        NSString *filePath = [[self class] pathForMediaItem:mediaItem];
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

+ (NSString *)pathForMediaItem:(OTRMediaItem *)mediaItem
{
    NSString *path = nil;
    NSString *buddyUniqueId = [self buddyUniqueIdForMeidaItem:mediaItem];
    if ([buddyUniqueId length] && [mediaItem.uniqueId length] && [mediaItem.filename length]) {
        path = [NSString pathWithComponents:@[rootMediaDirectory,buddyUniqueId,mediaItem.uniqueId,mediaItem.filename]];
    }
    return path;
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
