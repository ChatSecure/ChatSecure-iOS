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
#import "OTRMessage.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRProtocolManager.h"
#import "OTRDatabaseManager.h"

#import "OTRLog.h"

NSString *const OTRMessageStateDidChangeNotification = @"OTREncryptionManagerMessageStateDidChangeNotification";
NSString *const OTRWillStartGeneratingPrivateKeyNotification = @"OTREncryptionManagerWillStartGeneratingPrivateKeyNotification";
NSString *const OTRDidFinishGeneratingPrivateKeyNotification = @"OTREncryptionManagerdidFinishGeneratingPrivateKeyNotification";
NSString *const OTRMessageStateKey = @"OTREncryptionManagerMessageStateKey";

@interface OTREncryptionManager ()

@property (nonatomic, strong)YapDatabaseConnection *databaseConnection;

@end

@implementation OTREncryptionManager


- (id) init {
    if (self = [super init]) {
        OTRKit *otrKit = [OTRKit sharedInstance];
        [otrKit setupWithDataPath:nil];
        self.databaseConnection = [OTRDatabaseManager sharedInstance].readWriteDatabaseConnection;
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

- (OTRProtocolType)prototcolTypeForString:(NSString *)typeString
{
    if ([typeString isEqualToString:kOTRProtocolTypeXMPP])
    {
        return OTRProtocolTypeXMPP;
    }
    else {
        return OTRProtocolTypeNone;
    }
}


#pragma mark OTRKitDelegate methods

- (void)otrKit:(OTRKit *)otrKit injectMessage:(NSString *)text username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag
{
    //only otrproltocol
    OTRMessage *message = [[OTRMessage alloc] init];
    message.text =text;
    message.incoming = NO;
    
    __block OTRBuddy *buddy = nil;
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [OTRBuddy fetchBuddyForUsername:username accountName:accountName protocolType:[self prototcolTypeForString:protocol] transaction:transaction];
    } completionBlock:^{
        message.buddyUniqueId = buddy.uniqueId;
        
        [[OTRProtocolManager sharedInstance] sendMessage:message];
    }];
}

- (void)otrKit:(OTRKit *)otrKit encodedMessage:(NSString *)encodedMessage username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag error:(NSError *)error
{
    if (error) {
        DDLogError(@"Encode Error: %@",error);
    }
    
    OTRMessage *message = nil;
    if ([tag isKindOfClass:[OTRMessage class]]) {
        message = [tag copy];
    }
    
    if (message && [encodedMessage length]) {
    
        if (![[encodedMessage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:[message.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]) {
             message.transportedSecurely = YES;
        }
        
        message.text = encodedMessage;
        [[OTRProtocolManager sharedInstance] sendMessage:message];
    }
    
}

- (void)otrKit:(OTRKit *)otrKit decodedMessage:(NSString *)decodedMessage tlvs:(NSArray *)tlvs username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag
{
    //decoded message can be nil if just TLV
    OTRMessage *message = nil;
    if ([tag isKindOfClass:[OTRMessage class]]) {
        message = tag;
    }
    
    if (message) {
        if ([decodedMessage length]) {
            message.text = decodedMessage;
            message.transportedSecurely = YES;
        }
        
        [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [message saveWithTransaction:transaction];
        }];
        
    }
    
    if ([tlvs count]) {
        DDLogVerbose(@"Found TLVS: %@",tlvs);
    }
}

- (void)otrKit:(OTRKit *)otrKit updateMessageState:(OTRKitMessageState)messageState username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol
{
    __block OTRBuddy *buddy = nil;
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [OTRBuddy fetchBuddyForUsername:username accountName:accountName protocolType:[self prototcolTypeForString:protocol] transaction:transaction];
    } completionBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OTRMessageStateDidChangeNotification object:buddy userInfo:@{OTRMessageStateKey:@(messageState)}];
    }];
}

- (BOOL)       otrKit:(OTRKit*)otrKit
   isUsernameLoggedIn:(NSString*)username
          accountName:(NSString*)accountName
             protocol:(NSString*)protocol {
    
    __block OTRBuddy *buddy = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [OTRBuddy fetchBuddyForUsername:username accountName:accountName protocolType:[self prototcolTypeForString:protocol] transaction:transaction];
    }];
    
    if(!buddy || buddy.status == OTRBuddyStatusOffline) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void)                           otrKit:(OTRKit*)otrKit
  showFingerprintConfirmationForTheirHash:(NSString*)theirHash
                                  ourHash:(NSString*)ourHash
                                 username:(NSString*)username
                              accountName:(NSString*)accountName
                                 protocol:(NSString*)protocol
{
    //changed user fingerprint
}

- (void) otrKit:(OTRKit*)otrKit
 handleSMPEvent:(OTRKitSMPEvent)event
       progress:(double)progress
       question:(NSString*)question
       username:(NSString*)username
    accountName:(NSString*)accountName
       protocol:(NSString*)protocol
{
    
}

- (void) otrKit:(OTRKit *)otrKit handleMessageEvent:(OTRKitMessageEvent)event message:(NSString *)message username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol tag:(id)tag error:(NSError *)error {
    //incoming and outgoing errors and other events
    DDLogWarn(@"Message Event: %lu Error:%@",event,error);
    
}

- (void)        otrKit:(OTRKit*)otrKit
  receivedSymmetricKey:(NSData*)symmetricKey
                forUse:(NSUInteger)use
               useData:(NSData*)useData
              username:(NSString*)username
           accountName:(NSString*)accountName
              protocol:(NSString*)protocol
{
    DDLogVerbose(@"Received Symetric Key");
}

 ////// Optional //////

- (void)otrKit:(OTRKit *)otrKit willStartGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol
{
    __block OTRAccount *account = nil;
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [OTRAccount fetchAccountWithUsername:accountName protocolType:[self prototcolTypeForString:protocol] transaction:transaction];
    } completionBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OTRWillStartGeneratingPrivateKeyNotification object:account];
    }];
    
    
}

- (void)otrKit:(OTRKit *)otrKit didFinishGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol error:(NSError *)error
{
    __block OTRAccount *account = nil;
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [OTRAccount fetchAccountWithUsername:accountName protocolType:[self prototcolTypeForString:protocol] transaction:transaction];
    } completionBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OTRDidFinishGeneratingPrivateKeyNotification object:account];
    }];
}

#pragma - mark Class Methods

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
