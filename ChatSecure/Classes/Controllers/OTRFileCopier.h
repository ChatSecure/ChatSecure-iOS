//
//  OTRFileCopier.h
//  ChatSecure
//
//  Created by David Chiles on 2/24/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"

@class IOCipher;

@interface OTRFileCopier : MTLModel <NSCopying>

@property (nonatomic, strong, readonly) NSString *filePath;
@property (nonatomic, strong, readonly) NSString *encryptedFilePath;
@property (nonatomic, weak, readonly) IOCipher *ioCipher;
@property (nonatomic, strong, readonly) void (^completion)(NSInteger, NSError *);
@property (nonatomic, strong, readonly) dispatch_queue_t completionQueue;

- (instancetype)initWithFilePath:(NSString *)filePath
                 toEncryptedPath:(NSString *)path
                        ioCipher:(IOCipher *)ioCipher
                 completionQueue:(dispatch_queue_t) completionQueue
                      completion:(void (^)(NSInteger, NSError *))completion;


- (void)start;

@end
