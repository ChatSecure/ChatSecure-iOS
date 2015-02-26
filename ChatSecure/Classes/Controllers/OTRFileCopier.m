//
//  OTRFileCopier.m
//  ChatSecure
//
//  Created by David Chiles on 2/24/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRFileCopier.h"
#import "IOCipher.h"

@interface OTRFileCopier () <NSStreamDelegate>

@property (nonatomic, strong) NSNumber *bytesWritten;

@end

@implementation OTRFileCopier

- (instancetype)init
{
    if (self = [super init]) {
        self.bytesWritten = @(0);
    }
    return self;
}

- (instancetype)initWithFilePath:(NSString *)filePath toEncryptedPath:(NSString *)path ioCipher:(IOCipher *)ioCipher completionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSInteger, NSError *))completion
{
    if (self = [self init]) {
        _filePath = filePath;
        _encryptedFilePath = path;
        _ioCipher = ioCipher;
        _completion = completion;
        if (completionQueue) {
            _completionQueue = completionQueue;
        } else {
            _completionQueue = dispatch_get_main_queue();
        }
    }
    return self;
}

- (void)start
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:self.filePath];
        inputStream.delegate = self;
        
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];
        [inputStream open];
        
        [[NSRunLoop currentRunLoop] run];
    });
}

#pragma - mark NSStream Methods

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t buf[4096];
            NSInteger len = 0;
            len = [(NSInputStream *)stream read:buf maxLength:1024];
            if(len) {
                NSData *data = [NSData dataWithBytes:(const void *)buf length:len];
                [self.ioCipher writeDataToFileAtPath:self.encryptedFilePath
                                                data:data
                                              offset:self.bytesWritten.unsignedIntegerValue
                                               error:nil];
                self.bytesWritten = @(self.bytesWritten.unsignedIntegerValue + len);
            }
            
            break;
        }
        case NSStreamEventEndEncountered:
        {
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSDefaultRunLoopMode];
            if (self.completion) {
                __weak typeof(self)weakSelf = self;
                dispatch_async(self.completionQueue, ^{
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf.completion(strongSelf.bytesWritten.unsignedIntegerValue,nil);
                });
            }
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            if (self.completion) {
                __weak typeof(self)weakSelf = self;
                dispatch_async(self.completionQueue, ^{
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf.completion(strongSelf.bytesWritten.unsignedIntegerValue,stream.streamError);
                });
            }
        }
            
            
        default:
            break;
    }
}

@end
