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

#import "OTRLog.h"

@implementation OTREncryptionManager


- (id) init {
    if (self = [super init]) {
        OTRKit *otrKit = [OTRKit sharedInstance];
        otrKit.delegate = self;
        NSArray *protectPaths = @[otrKit.privateKeyPath, otrKit.fingerprintsPath, otrKit.instanceTagsPath];
        for (NSString *path in protectPaths) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [@"" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            [OTREncryptionManager setFileProtection:NSFileProtectionCompleteUntilFirstUserAuthentication path:path];
            [OTREncryptionManager addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:path]];
        }
    }
    return self;
}


#pragma mark OTRKitDelegate methods

- (void) updateMessageStateForUsername:(NSString*)username accountName:(NSString*)accountName protocol:(NSString*)protocol messageState:(OTRKitMessageState)messageState {
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedBuddy *buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:username accountName:accountName protocol:protocol inContext:context];
    [buddy setNewEncryptionStatus:messageState inContext:context];
    [context MR_saveToPersistentStoreAndWait];
}

- (void) injectMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol {
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedMessage *newMessage = [OTRManagedMessage newMessageToBuddy:[[OTRProtocolManager sharedInstance] buddyForUserName:recipient accountName:accountName protocol:protocol inContext:context] message:message encrypted:YES inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    [OTRProtocolManager sendMessage:newMessage];
}

-(BOOL)recipientIsLoggedIn:(NSString *)recipient accountName:(NSString *)accountName protocol:(NSString *)protocol
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    OTRManagedBuddy * buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:recipient accountName:accountName protocol:protocol inContext:context];
    [context MR_saveToPersistentStoreAndWait];
    if(buddy.currentStatusValue == OTRBuddyStatusOffline)
    {
        return NO;
    }
    else{
        return YES;
    }
}

+ (BOOL) setFileProtection:(NSString*)fileProtection path:(NSString*)path {
    NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:fileProtection forKey:NSFileProtectionKey];
    NSError * error = nil;
    BOOL success = [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:path error:&error];
    if (!success)
    {
        DDLogError(@"error encrypting store: %@", error.userInfo);
    }
    return success;
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        DDLogError(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

@end
