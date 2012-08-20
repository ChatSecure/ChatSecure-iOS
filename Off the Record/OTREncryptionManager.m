//
//  OTREncryptionManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTREncryptionManager.h"
#import "OTRMessage.h"
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

    OTRBuddy *buddy = [[OTRProtocolManager sharedInstance] buddyForUserName:username accountName:accountName protocol:protocol];
    
    if(messageState == kOTRKitMessageStateEncrypted)
    {
        buddy.encryptionStatus = kOTRBuddyEncryptionStatusEncrypted;
    }
    else
    {
        buddy.encryptionStatus = kOTRBuddyEncryptionStatusUnencrypted;
    }
}

- (void) injectMessage:(NSString*)message recipient:(NSString*)recipient accountName:(NSString*)accountName protocol:(NSString*)protocol {
    OTRMessage *newMessage = [OTRMessage messageWithBuddy:[[OTRProtocolManager sharedInstance] buddyForUserName:recipient accountName:accountName protocol:protocol] message:message];
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
