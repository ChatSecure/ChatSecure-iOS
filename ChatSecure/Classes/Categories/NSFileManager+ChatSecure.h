//
//  NSFileManager+ChatSecure.h
//  ChatSecure
//
//  Created by David Chiles on 5/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;

@interface NSFileManager (ChatSecure)


- (void)otr_enumerateFilesInDirectory:(NSString *)directory block:(void (^)(NSString *fullPath,BOOL *stop))enumerateBlock;
- (BOOL)otr_setFileProtection:(NSString *)fileProtection forFilesInDirectory:(NSString *)directory;
- (BOOL)otr_excudeFromBackUpFilesInDirectory:(NSString *)directory;

@end
