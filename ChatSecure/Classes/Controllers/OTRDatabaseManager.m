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
#import "OTRSettingsManager.h"
#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "ChatSecureCoreCompat-Swift.h"


@interface OTRDatabaseManager ()

@property (nonatomic, strong, nullable) YapDatabase *database;
@property (nonatomic, strong, nullable) YapDatabaseActionManager *actionManager;
@property (nonatomic, strong, nullable) NSString *inMemoryPassphrase;

@property (nonatomic, strong) id yapDatabaseNotificationToken;
@property (nonatomic, strong) id allowPassphraseBackupNotificationToken;
@property (nonatomic, readonly, nullable) YapTaskQueueBroker *messageQueueBroker;

@end

@implementation OTRDatabaseManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        __weak __typeof__(self) weakSelf = self;
        self.allowPassphraseBackupNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:kOTRSettingsValueUpdatedNotification
                                                                                                        object:kOTRSettingKeyAllowDBPassphraseBackup
                                                                                                         queue:[NSOperationQueue mainQueue]
                                                                                                    usingBlock:^(NSNotification *_Nonnull note) {
                                                                                                        [weakSelf updatePassphraseAccessibility];
                                                                                                    }];
    }

    return self;
}

- (BOOL) setupDatabaseWithName:(NSString*)databaseName {
    return [self setupDatabaseWithName:databaseName withMediaStorage:YES];
}

- (BOOL) setupDatabaseWithName:(NSString*)databaseName withMediaStorage:(BOOL)withMediaStorage {
    return [self setupDatabaseWithName:databaseName directory:nil withMediaStorage:withMediaStorage];
}

- (BOOL)setupDatabaseWithName:(NSString*)databaseName
                    directory:(nullable NSString*)directory
             withMediaStorage:(BOOL)withMediaStorage {
    BOOL success = NO;
    if ([self setupYapDatabaseWithName:databaseName directory:directory] )
    {
        success = YES;
    }
    if (success && withMediaStorage) success = [self setupSecureMediaStorage];
    
    //Enumerate all files in yap database directory and exclude from backup
    if (success) success = [[NSFileManager defaultManager] otr_excudeFromBackUpFilesInDirectory:self.databaseDirectory];
    //fix file protection on existing files
     if (success) success = [[NSFileManager defaultManager] otr_setFileProtection:NSFileProtectionCompleteUntilFirstUserAuthentication forFilesInDirectory:self.databaseDirectory];
    return success;
}

- (void)dealloc {
    if (self.yapDatabaseNotificationToken != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.yapDatabaseNotificationToken];
    }
    if (self.allowPassphraseBackupNotificationToken != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.allowPassphraseBackupNotificationToken];
    }
}

- (BOOL)setupSecureMediaStorage
{
    NSString *password = [self databasePassphrase];
    NSString *path = self.databaseDirectory;
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

- (BOOL)setupYapDatabaseWithName:(NSString *)name directory:(nullable NSString*)directory
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
    options.cipherCompatability = YapDatabaseCipherCompatability_Version3;
    _databaseDirectory = [directory copy];
    if (!_databaseDirectory) {
        _databaseDirectory = [[self class] defaultYapDatabaseDirectory];
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.databaseDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.databaseDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *databasePath = [self.databaseDirectory stringByAppendingPathComponent:name];
    
    self.database = [[YapDatabase alloc] initWithPath:databasePath
                                           serializer:nil
                                         deserializer:nil
                                              options:options];
    // Stop trying to setup up the database. Something went wrong. Most likely the password is incorrect.
    if (self.database == nil) {
        return NO;
    }
    
    self.database.connectionDefaults.objectPolicy = YapDatabasePolicyShare;
    self.database.connectionDefaults.objectCacheLimit = 10000;
    
    [self setupConnections];
    
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
    
    _messageQueueHandler = [[MessageQueueHandler alloc] initWithDbConnection:self.writeConnection];
    
    ////// Register Extensions////////
    
    //Async register all the views
    dispatch_block_t registerExtensions = ^{
        // Register realtionship extension
        YapDatabaseRelationship *databaseRelationship = [[YapDatabaseRelationship alloc] initWithVersionTag:@"1"];
        
        [self.database registerExtension:databaseRelationship withName:[YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName]];
        
        // Register Secondary Indexes
        YapDatabaseSecondaryIndex *signalIndex = YapDatabaseSecondaryIndex.signalIndex;
        [self.database registerExtension:signalIndex withName:SecondaryIndexName.signal];
        YapDatabaseSecondaryIndex *messageIndex = YapDatabaseSecondaryIndex.messageIndex;
        [self.database registerExtension:messageIndex withName:SecondaryIndexName.messages];
        YapDatabaseSecondaryIndex *roomOccupantIndex = YapDatabaseSecondaryIndex.roomOccupantIndex;
        [self.database registerExtension:roomOccupantIndex withName:SecondaryIndexName.roomOccupants];
        YapDatabaseSecondaryIndex *buddyIndex = YapDatabaseSecondaryIndex.buddyIndex;
        [self.database registerExtension:buddyIndex withName:SecondaryIndexName.buddy];
        YapDatabaseSecondaryIndex *mediaItemIndex = YapDatabaseSecondaryIndex.mediaItemIndex;
        [self.database registerExtension:mediaItemIndex withName:SecondaryIndexName.mediaItems];

        // Register action manager
        self.actionManager = [[YapDatabaseActionManager alloc] init];
        NSString *actionManagerName = [YapDatabaseConstants extensionName:DatabaseExtensionNameActionManagerName];
        [self.database registerExtension:self.actionManager withName:actionManagerName];
        
        [OTRDatabaseView registerAllAccountsDatabaseViewWithDatabase:self.database];
        [OTRDatabaseView registerChatDatabaseViewWithDatabase:self.database];
        // Order is important - the conversation database view uses the lastMessageWithTransaction: method which in turn uses the OTRFilteredChatDatabaseViewExtensionName view registered above.
        [OTRDatabaseView registerConversationDatabaseViewWithDatabase:self.database];
        [OTRDatabaseView registerAllBuddiesDatabaseViewWithDatabase:self.database];
        
        
        NSString *name = [YapDatabaseConstants extensionName:DatabaseExtensionNameMessageQueueBrokerViewName];
        self->_messageQueueBroker = [YapTaskQueueBroker setupWithDatabase:self.database name:name handler:self.messageQueueHandler error:nil];
        
        
        //Register Buddy username & displayName FTS and corresponding view
        YapDatabaseFullTextSearch *buddyFTS = [OTRYapExtensions buddyFTS];
        NSString *FTSName = [YapDatabaseConstants extensionName:DatabaseExtensionNameBuddyFTSExtensionName];
        NSString *AllBuddiesName = OTRAllBuddiesDatabaseViewExtensionName;
        [self.database registerExtension:buddyFTS withName:FTSName];
        YapDatabaseSearchResultsView *searchResultsView = [[YapDatabaseSearchResultsView alloc] initWithFullTextSearchName:FTSName parentViewName:AllBuddiesName versionTag:nil options:nil];
        NSString* viewName = [YapDatabaseConstants extensionName:DatabaseExtensionNameBuddySearchResultsViewName];
        [self.database registerExtension:searchResultsView withName:viewName];
        
        // Remove old unused objects
        [self.writeConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [transaction removeAllObjectsInCollection:OTRXMPPPresenceSubscriptionRequest.collection];
        }];
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
        return NO;
    }
}

- (void) setupConnections {
    _uiConnection = [self.database newConnection];
    self.uiConnection.name = @"uiConnection";
    
    _readConnection = [self.database newConnection];
    self.readConnection.name = @"readConnection";
    
    _writeConnection = [self.database newConnection];
    self.writeConnection.name = @"writeConnection";
    
    _longLivedReadOnlyConnection = [self.database newConnection];
    self.longLivedReadOnlyConnection.name = @"LongLivedReadOnlyConnection";
    
#if DEBUG
    self.uiConnection.permittedTransactions = YDB_SyncReadTransaction | YDB_MainThreadOnly;
    self.readConnection.permittedTransactions = YDB_AnyReadTransaction;
    // TODO: We can do better work at isolating work between connections
    //self.writeConnection.permittedTransactions = YDB_AnyReadWriteTransaction;
    self.longLivedReadOnlyConnection.permittedTransactions = YDB_AnyReadTransaction; // | YDB_MainThreadOnly;
#endif
}

- (YapDatabaseConnection *)newConnection
{
    return [self.database newConnection];
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

+ (NSString *)defaultYapDatabaseDirectory {
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    NSString *directory = [applicationSupportDirectory stringByAppendingPathComponent:applicationName];
    return directory;
}

+ (NSString *)defaultYapDatabasePathWithName:(NSString *)name
{
    return [[self defaultYapDatabaseDirectory] stringByAppendingPathComponent:name];
}

+ (BOOL)existsYapDatabase
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self defaultYapDatabasePathWithName:OTRYapDatabaseName]];
}

- (BOOL) setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error
{
    BOOL result = YES;
    if (rememeber) {
        self.inMemoryPassphrase = nil;
        result = [SAMKeychain setPassword:passphrase forService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName error:error];
    } else {
        [SAMKeychain deletePasswordForService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName];
        self.inMemoryPassphrase = passphrase;
    }
    return result;
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

- (void)updatePassphraseAccessibility
{
    if (self.hasPassphrase && self.inMemoryPassphrase == nil) {
        BOOL allowBackup = [OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyAllowDBPassphraseBackup];

        CFTypeRef previousAccessibilityType = [SAMKeychain accessibilityType];
        [SAMKeychain setAccessibilityType:allowBackup ? kSecAttrAccessibleAfterFirstUnlock : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];

        NSError *error = nil;
        [self setDatabasePassphrase:self.databasePassphrase remember:YES error:&error];
        if (error) {
            DDLogError(@"Password Error: %@",error);
        }

        [SAMKeychain setAccessibilityType:previousAccessibilityType];
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
