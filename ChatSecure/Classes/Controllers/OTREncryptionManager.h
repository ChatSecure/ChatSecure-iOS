//
//  OTREncryptionManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import <Foundation/Foundation.h>
@import OTRKit;

@class OTRPushTLVHandler;

extern NSString *const OTRMessageStateDidChangeNotification;
extern NSString *const OTRWillStartGeneratingPrivateKeyNotification;
extern NSString *const OTRDidFinishGeneratingPrivateKeyNotification;
extern NSString *const OTRMessageStateKey;

extern NSString *const OTREncryptionError;
extern NSString *const OTRMessageEventKey;

// This is a hack to get around problems using OTRKit.h in swift files
typedef NS_ENUM(NSUInteger, OTREncryptionMessageState) {
    OTREncryptionMessageStatePlaintext,
    OTREncryptionMessageStateEncrypted,
    OTREncryptionMessageStateFinished,
    OTREncryptionMessageStateError
};

@interface OTREncryptionManager:NSObject


@property (nonatomic, strong, readonly) OTRKit *otrKit;
@property (nonatomic, strong, readonly) OTRDataHandler *dataHandler;
@property (nonatomic, strong, readonly) OTRPushTLVHandler *pushTLVHandler;

+ (BOOL) setFileProtection:(NSString*)fileProtection path:(NSString*)path;
+ (BOOL) addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

+ (OTREncryptionMessageState)convertEncryptionState:(NSUInteger)messageState;



@end