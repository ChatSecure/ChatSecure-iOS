//
//  OTREncryptionManager.m
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

#import "OTREncryptionManager.h"
#import "OTRManagedMessage.h"
#import "OTRProtocolManager.h"

@implementation OTREncryptionManager


- (id) init {
    if (self = [super init]) {
        [OTRKit sharedInstance].delegate = self;
        
    }
    return self;
}


#pragma mark OTRKitDelegate methods

- (void) updateMessageStateForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*)protocol messageState:(OTRKitMessageState)messageState {

    OTRManagedBuddy *buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:username accountName:accountName protocol:protocol];
    [buddy setNewEncryptionStatus:messageState];
}

- (void) injectMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol {
    OTRManagedMessage *newMessage = [OTRManagedMessage newMessageToBuddy:[[OTRProtocolManager sharedInstance] buddyForUserName:recipient accountName:accountName protocol:protocol] message:message encrypted:YES];
    [newMessage send];
}

+ (void) protectFileWithPath:(NSString*)path {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey] ofItemAtPath:path error:&error];
    if (error) 
    {
        NSLog(@"Error setting file protection key for %@: %@%@",path,[error localizedDescription], [error userInfo]);
        error = nil;
    }
}

@end
