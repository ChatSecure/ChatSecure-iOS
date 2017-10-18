//
//  OTRDatabaseManager.m
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseManager.h"

#import "OTREncryptionManager.h"
#import "OTRLog.h"
#import "OTRDatabaseView.h"
@import SAMKeychain;
#import "OTRConstants.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPTorAccount.h"
#import "OTRGoogleOAuthXMPPAccount.h"
#import "OTRAccount.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"
#import "OTRMediaFileManager.h"
@import IOCipher;
#import "NSFileManager+ChatSecure.h"
@import OTRAssets;
@import YapDatabase;
@import YapTaskQueue;

#import "OTRSignalSession.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

NSString *const OTRMessagesSecondaryIndex = @"OTRMessagesSecondaryIndex";
NSString *const OTRYapDatabaseMessageIdSecondaryIndexColumnName = @"OTRYapDatabaseMessageIdSecondaryIndexColumnName";
NSString *const OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName = @"OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName";
NSString *const OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName = @"OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName";
NSString *const OTRYapDatabaseRoomOccupantJidSecondaryIndexColumnName = @"OTRYapDatabaseRoomOccupantJidSecondaryIndexColumnName";
NSString *const OTRYapDatabaseUnreadMessageSecondaryIndexColumnName = @"OTRYapDatabaseUnreadMessageSecondaryIndexColumnName";
NSString *const OTRYapDatabaseSignalSessionSecondaryIndexColumnName = @"OTRYapDatabaseSignalSessionSecondaryIndexColumnName";
NSString *const OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName = @"OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName";
NSString *const OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName = @"OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName";


@interface OTRDatabaseManager ()

@property (nonatomic, strong, nullable) YapDatabase *database;
@property (nonatomic, strong, nullable) YapDatabaseConnection *readOnlyDatabaseConnection;
@property (nonatomic, strong, nullable) YapDatabaseConnection *readWriteDatabaseConnection;
@property (nonatomic, strong, nullable) YapDatabaseActionManager *actionManager;
@property (nonatomic, strong, nullable) NSString *inMemoryPassphrase;

@property (nonatomic, strong) id yapDatabaseNotificationToken;
@property (nonatomic, readonly, nullable) YapTaskQueueBroker *messageQueueBroker;

@end

@implementation OTRDatabaseManager
- (BOOL) setupDatabaseWithName:(NSString*)databaseName {
    return [self setupDatabaseWithName:databaseName withMediaStorage:YES];
}

- (BOOL) setupDatabaseWithName:(NSString*)databaseName withMediaStorage:(BOOL)withMediaStorage {
    BOOL success = NO;
    if ([self setupYapDatabaseWithName:databaseName] )
    {
        success = YES;
    }
    if (success && withMediaStorage) success = [self setupSecureMediaStorage];
    
    NSString *databaseDirectory = [OTRDatabaseManager yapDatabaseDirectory];
    //Enumerate all files in yap database directory and exclude from backup
    if (success) success = [[NSFileManager defaultManager] otr_excudeFromBackUpFilesInDirectory:databaseDirectory];
    //fix file protection on existing files
     if (success) success = [[NSFileManager defaultManager] otr_setFileProtection:NSFileProtectionCompleteUntilFirstUserAuthentication forFilesInDirectory:databaseDirectory];
    return success;
}

- (void)dealloc {
    if (self.yapDatabaseNotificationToken != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.yapDatabaseNotificationToken];
    }
}

- (BOOL)setupSecureMediaStorage
{
    NSString *password = [self databasePassphrase];
    NSString *path = [OTRDatabaseManager yapDatabasePathWithName:nil];
    path = [path stringByAppendingPathComponent:@"ChatSecure-media.sqlite"];
    BOOL success = [[OTRMediaFileManager sharedInstance] setupWithPath:path password:password];
    
    self.mediaServer = [OTRMediaServer sharedInstance];
    NSError *error = nil;
    BOOL mediaServerStarted = [self.mediaServer startOnPort:0 error:&error];
    if (!mediaServerStarted) {
        DDLogError(@"Error starting media server: %@",error);
    }
    return success;
}

- (BOOL)setupYapDatabaseWithName:(NSString *)name
{
    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Fail;
    options.cipherKeyBlock = ^{
        NSString *passphrase = [self databasePassphrase];
        NSData *keyData = [passphrase dataUsingEncoding:NSUTF8StringEncoding];
        if (!keyData.length) {
            [NSException raise:@"Must have passphrase of length > 0" format:@"password length is %d.", (int)keyData.length];
        }
        return keyData;
    };
    
    NSString *databaseDirectory = [[self class] yapDatabaseDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:databaseDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:databaseDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *databasePath = [[self class] yapDatabasePathWithName:name];
    
    
    self.database = [[YapDatabase alloc] initWithPath:databasePath
                                           serializer:nil
                                         deserializer:nil
                                              options:options];
    // Stop trying to setup up the database. Something went wrong. Most likely the password is incorrect.
    if (self.database == nil) {
        return NO;
    }
    
    self.database.defaultObjectPolicy = YapDatabasePolicyShare;
    self.database.defaultObjectCacheLimit = 10000;
    
    self.readOnlyDatabaseConnection = [self.database newConnection];
    self.readOnlyDatabaseConnection.name = @"readOnlyDatabaseConnection";

    
    self.readWriteDatabaseConnection = [self.database newConnection];
    self.readWriteDatabaseConnection.name = @"readWriteDatabaseConnection";

    
    _longLivedReadOnlyConnection = [self.database newConnection];
    self.longLivedReadOnlyConnection.name = @"LongLivedReadOnlyConnection";
    
#if DEBUG
    self.readOnlyDatabaseConnection.permittedTransactions = YDB_AnyReadTransaction;
    // TODO: We can do better work at isolating work between connections
    //self.readWriteDatabaseConnection.permittedTransactions = YDB_AnyReadWriteTransaction;
    //self.longLivedReadOnlyConnection.permittedTransactions = YDB_MainThreadOnly;
#endif
    
    __weak __typeof__(self) weakSelf = self;
    self.yapDatabaseNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:YapDatabaseModifiedNotification object:self.database queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSArray <NSNotification *>*changes = [weakSelf.longLivedReadOnlyConnection beginLongLivedReadTransaction];
        if (changes != nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:[DatabaseNotificationName LongLivedTransactionChanges]
                                                                object:weakSelf.longLivedReadOnlyConnection
                                                              userInfo:@{[DatabaseNotificationKey ConnectionChanges]:changes}];
        }
        
    }];
    [self.longLivedReadOnlyConnection beginLongLivedReadTransaction];
    
    _messageQueueHandler = [[MessageQueueHandler alloc] initWithDbConnection:self.readWriteDatabaseConnection];
    
    ////// Register Extensions////////
    
    //Async register all the views
    dispatch_block_t registerExtensions = ^{
        // Register realtionship extension
        YapDatabaseRelationship *databaseRelationship = [[YapDatabaseRelationship alloc] initWithVersionTag:@"1"];
        
        [self.database registerExtension:databaseRelationship withName:[YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName]];
        
        // Register Secondary Index
        YapDatabaseSecondaryIndex *secondaryIndex = [self setupSecondaryIndexes];
        [self.database registerExtension:secondaryIndex withName:[YapDatabaseConstants extensionName:DatabaseExtensionNameSecondaryIndexName]];
        YapDatabaseSecondaryIndex *messageIndex = [self setupMessageSecondaryIndexes];
        [self.database registerExtension:messageIndex withName:OTRMessagesSecondaryIndex];
        
        // Register action manager
        self.actionManager = [[YapDatabaseActionManager alloc] init];
        NSString *actionManagerName = [YapDatabaseConstants extensionName:DatabaseExtensionNameActionManagerName];
        [self.database registerExtension:self.actionManager withName:actionManagerName];
        
        [OTRDatabaseView registerAllAccountsDatabaseViewWithDatabase:self.database];
        [OTRDatabaseView registerConversationDatabaseViewWithDatabase:self.database];
        [OTRDatabaseView registerChatDatabaseViewWithDatabase:self.database];
        [OTRDatabaseView registerAllBuddiesDatabaseViewWithDatabase:self.database];
        [OTRDatabaseView registerAllSubscriptionRequestsViewWithDatabase:self.database];
        
        
        NSString *name = [YapDatabaseConstants extensionName:DatabaseExtensionNameMessageQueueBrokerViewName];
        _messageQueueBroker = [YapTaskQueueBroker setupWithDatabase:self.database name:name handler:self.messageQueueHandler error:nil];
        
        
        //Register Buddy username & displayName FTS and corresponding view
        YapDatabaseFullTextSearch *buddyFTS = [OTRYapExtensions buddyFTS];
        NSString *FTSName = [YapDatabaseConstants extensionName:DatabaseExtensionNameBuddyFTSExtensionName];
        NSString *AllBuddiesName = OTRAllBuddiesDatabaseViewExtensionName;
        [self.database registerExtension:buddyFTS withName:FTSName];
        YapDatabaseSearchResultsView *searchResultsView = [[YapDatabaseSearchResultsView alloc] initWithFullTextSearchName:FTSName parentViewName:AllBuddiesName versionTag:nil options:nil];
        NSString* viewName = [YapDatabaseConstants extensionName:DatabaseExtensionNameBuddySearchResultsViewName];
        [self.database registerExtension:searchResultsView withName:viewName];
    };
    
#if DEBUG
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    // This can make it easier when writing tests
    if (environment[@"SYNC_DB_STARTUP"]) {
        registerExtensions();
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), registerExtensions);
    }
#else
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), registerExtensions);
#endif
    
    
    if (self.database != nil) {
        return YES;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:Database_Error_String() message:Could_Not_Decrypt_Database() delegate:nil cancelButtonTitle:OK_STRING() otherButtonTitles:nil];
        [alert show];
        return NO;
    }
}

- (YapDatabaseConnection *)newConnection
{
    return [self.database newConnection];
}

- (YapDatabaseSecondaryIndex *)setupMessageSecondaryIndexes {
    YapDatabaseSecondaryIndexSetup *setup = [[YapDatabaseSecondaryIndexSetup alloc] init];
    [setup addColumn:OTRYapDatabaseMessageIdSecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeText];
    [setup addColumn:OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeText];
    [setup addColumn:OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeText];
    [setup addColumn:OTRYapDatabaseUnreadMessageSecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeInteger];
    [setup addColumn:SecondaryIndexName.originId withType:YapDatabaseSecondaryIndexTypeText];
    [setup addColumn:SecondaryIndexName.stanzaId withType:YapDatabaseSecondaryIndexTypeText];
    
    YapDatabaseSecondaryIndexHandler *indexHandler = [YapDatabaseSecondaryIndexHandler withObjectBlock:^(YapDatabaseReadTransaction * _Nonnull transaction, NSMutableDictionary * _Nonnull dict, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
        if ([object conformsToProtocol:@protocol(OTRMessageProtocol)])
        {
            id<OTRMessageProtocol> message = (id <OTRMessageProtocol>)object;
            if ([[message remoteMessageId] length]) {
                [dict setObject:[message remoteMessageId] forKey:OTRYapDatabaseRemoteMessageIdSecondaryIndexColumnName];
            }
            if ([message messageKey].length) {
                [dict setObject:[message messageKey] forKey:OTRYapDatabaseMessageIdSecondaryIndexColumnName];
            }
            [dict setObject:@(message.isMessageRead) forKey:OTRYapDatabaseUnreadMessageSecondaryIndexColumnName];
            if (message.threadId) {
                [dict setObject:message.threadId forKey:OTRYapDatabaseMessageThreadIdSecondaryIndexColumnName];
            }
            if (message.originId.length) {
                [dict setObject:message.originId forKey:SecondaryIndexName.originId];
            }
            if (message.stanzaId.length) {
                [dict setObject:message.stanzaId forKey:SecondaryIndexName.stanzaId];
            }
        }
    }];

    YapDatabaseSecondaryIndex *secondaryIndex = [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:indexHandler versionTag:@"5"];
    
    return secondaryIndex;
}


- (YapDatabaseSecondaryIndex *)setupSecondaryIndexes
{
    YapDatabaseSecondaryIndexSetup *setup = [[YapDatabaseSecondaryIndexSetup alloc] init];
    [setup addColumn:OTRYapDatabaseRoomOccupantJidSecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeText];
    [setup addColumn:OTRYapDatabaseSignalSessionSecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeText];
    [setup addColumn:OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeInteger];
    [setup addColumn:OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName withType:YapDatabaseSecondaryIndexTypeText];
    
    YapDatabaseSecondaryIndexHandler *indexHandler = [YapDatabaseSecondaryIndexHandler withObjectBlock:^(YapDatabaseReadTransaction * _Nonnull transaction, NSMutableDictionary * _Nonnull dict, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
        
        if ([collection isEqualToString:[OTRXMPPRoomOccupant collection]]) {
            OTRXMPPRoomOccupant *roomOccupant = (OTRXMPPRoomOccupant *)object;
            if ([roomOccupant.jid length]) {
                [dict setObject:roomOccupant.jid forKey:OTRYapDatabaseRoomOccupantJidSecondaryIndexColumnName];
            }
        }
        
        if ([object isKindOfClass:[OTRSignalSession class]]) {
            OTRSignalSession *session = (OTRSignalSession *)object;
            if ([session.name length]) {
                NSString *value = [NSString stringWithFormat:@"%@-%@",session.accountKey, session.name];
                [dict setObject:value forKey:OTRYapDatabaseSignalSessionSecondaryIndexColumnName];
            }
        }
        
        if ([object isKindOfClass:[OTRSignalPreKey class]]) {
            OTRSignalPreKey *preKey = (OTRSignalPreKey *)object;
            NSNumber *keyId = @(preKey.keyId);
            if (keyId) {
                [dict setObject:keyId forKey:OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName];
            }
            if (preKey.accountKey) {
                [dict setObject:preKey.accountKey forKey:OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName];
            }
        }
    }];
    
    YapDatabaseSecondaryIndex *secondaryIndex = [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:indexHandler versionTag:@"4"];
    
    return secondaryIndex;
}

+ (void) deleteLegacyXMPPFiles {
    NSString *xmppCapabilities = @"XMPPCapabilities";
    NSString *xmppvCard = @"XMPPvCard";
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSError *error = nil;
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:applicationSupportDirectory error:&error];
    if (error) {
        DDLogError(@"Error listing app support contents: %@", error);
    }
    for (NSString *path in paths) {
        if ([path rangeOfString:xmppCapabilities].location != NSNotFound || [path rangeOfString:xmppvCard].location != NSNotFound) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            if (error) {
                DDLogError(@"Error deleting legacy store: %@", error);
            }
        }
    }
}

+ (NSString *)yapDatabaseDirectory {
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    NSString *directory = [applicationSupportDirectory stringByAppendingPathComponent:applicationName];
    return directory;
}

+ (NSString *)yapDatabasePathWithName:(NSString *)name
{
    
    return [[self yapDatabaseDirectory] stringByAppendingPathComponent:name];
}

+ (BOOL)existsYapDatabase
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self yapDatabasePathWithName:OTRYapDatabaseName]];
}

- (void) setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error
{
    if (rememeber) {
        self.inMemoryPassphrase = nil;
        [SAMKeychain setPassword:passphrase forService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName error:error];
    } else {
        [SAMKeychain deletePasswordForService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName];
        self.inMemoryPassphrase = passphrase;
    }
}

- (BOOL)hasPassphrase
{
    return [self databasePassphrase].length != 0;
}

- (NSString *)databasePassphrase
{
    if (self.inMemoryPassphrase) {
        return self.inMemoryPassphrase;
    }
    else {
        return [SAMKeychain passwordForService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName];
    }
    
}

#pragma - mark Singlton Methodd

+ (OTRDatabaseManager*) shared {
    return [self sharedInstance];
}

+ (instancetype)sharedInstance
{
    static id databaseManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        databaseManager = [[self alloc] init];
    });
    
    return databaseManager;
}

@end
