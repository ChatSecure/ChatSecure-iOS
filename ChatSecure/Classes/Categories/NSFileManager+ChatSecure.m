//
//  NSFileManager+ChatSecure.m
//  ChatSecure
//
//  Created by David Chiles on 5/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "NSFileManager+ChatSecure.h"

@implementation NSFileManager (ChatSecure)

- (void)otr_enumerateFilesInDirectory:(NSString *)directory block:(void (^)(NSString *fullPath,BOOL *stop))enumerateBlock
{
    BOOL isDirecotry = NO;
    BOOL exists = [self fileExistsAtPath:directory isDirectory:&isDirecotry];
    if (enumerateBlock && isDirecotry && exists) {
        NSDirectoryEnumerator *directoryEnumerator = [self enumeratorAtPath:directory];
        NSString *file = nil;
        BOOL stop = NO;
        while ((file = [directoryEnumerator nextObject]) && !stop) {
            NSString *path = [NSString pathWithComponents:@[directory,file]];
            enumerateBlock(path,&stop);
        }
    }
}

- (BOOL)otr_setFileProtection:(NSString *)fileProtection forFilesInDirectory:(NSString *)directory
{
    __block BOOL success = YES;
    [self otr_enumerateFilesInDirectory:directory block:^(NSString *fullPath, BOOL *stop) {
        success = [self setAttributes:@{NSFileProtectionKey:fileProtection}
                                                   ofItemAtPath:fullPath error:nil];
        *stop = !success;
    }];
    return success;
}

- (BOOL)otr_excudeFromBackUpFilesInDirectory:(NSString *)directory
{
    __block BOOL success = YES;
    [self otr_enumerateFilesInDirectory:directory block:^(NSString *fullPath, BOOL *stop) {
        success = [self setAttributes:@{NSURLIsExcludedFromBackupKey:@(YES)} ofItemAtPath:fullPath error:nil];
        *stop = !success;
    }];
    return success;
}

@end
