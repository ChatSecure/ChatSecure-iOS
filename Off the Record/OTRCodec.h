//
//  OTRCodec.h
//  Off the Record
//
//  Created by Chris on 8/17/11.
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
#import "OTRManagedChatMessage.h"
#import "OTRManagedAccount.h"
#import "OTRKit.h"

@interface OTRCodec : NSObject

+ (void)decodeMessage:(OTRManagedChatMessage *)theMessage completionBlock:(void (^)(OTRManagedChatMessage * message))completionBlock;
+ (void)encodeMessage:(OTRManagedChatMessage *)theMessage completionBlock:(void (^)(OTRManagedChatMessage * message))completionBlock;

+ (void)generateOtrInitiateOrRefreshMessageTobuddy:(OTRManagedBuddy*)buddy
                                   completionBlock:(void (^)(OTRManagedChatMessage * message))completionBlock;

+ (void)generatePrivateKeyFor:(OTRManagedAccount *)account
              completionBlock:(void (^)(BOOL generatedKey))completionBlock;
+ (void)isGeneratingKeyForBuddy:(OTRManagedBuddy *)buddy
                     completion:(void (^)(BOOL isGeneratingKey))completion;

+ (void)hasGeneratedKeyForAccount:(OTRManagedAccount *)account
                completionBlock:(void (^)(BOOL hasGeneratedKey))completionBlock;

@end
