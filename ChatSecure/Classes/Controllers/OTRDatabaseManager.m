//
//  OTRDatabaseManager.m
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseManager.h"

#import "OTRManagedAccount.h"
#import "OTREncryptionManager.h"
#import "OTRLog.h"
#import "YapDatabaseRelationship.h"
#import "OTRDatabaseView.h"
#import "SSKeychain.h"
#import "OTRConstants.h"
#import "YapDatabaseSecondaryIndexSetup.h"
#import "YapDatabaseSecondaryIndex.h"

#import "OTRManagedOscarAccount.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPTorAccount.h"
#import "OTRManagedGoogleAccount.h"
#import "OTRManagedFacebookAccount.h"
#import "OTRGoogleOAuthXMPPAccount.h"
#import "OTRFacebookOAuthXMPPAccount.h"
#import "OTRAccount.h"
#import "CoreData+MagicalRecord.h"
#import "OTRMessage.h"

NSString *const OTRYapDatabaseRelationshipName = @"OTRYapDatabaseRelationshipName";
NSString *const OTRYapDatabseMessageIdSecondaryIndex = @"OTRYapDatabseMessageIdSecondaryIndex";
NSString *const OTRYapDatabseMessageIdSecondaryIndexExtension = @"OTRYapDatabseMessageIdSecondaryIndexExtension";


@interface OTRDatabaseManager ()

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *readOnlyDatabaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *readWriteDatabaseConnection;
@property (nonatomic, strong) NSString *inMemoryPassphrase;

@end

@implementation OTRDatabaseManager

- (BOOL) setupDatabaseWithName:(NSString*)databaseName {
    if ([self setupYapDatabaseWithName:databaseName] )
    {
        [self migrateCoreDataToYapDatabase];
        return YES;
    }
    return NO;
}

- (void)migrateCoreDataToYapDatabase
{
    NSString *legacyDatabaseName = @"db.sqlite";
    NSURL * legacyDatabaseURL = [NSPersistentStore MR_urlForStoreName:legacyDatabaseName];
    
    NSURL * databaseURL = [NSPersistentStore MR_urlForStoreName:@"ChatSecure.sqlite"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:legacyDatabaseURL.path]) {
        // migrate store
        if([OTRDatabaseManager migrateLegacyStore:legacyDatabaseURL destinationStore:databaseURL]) {
            [fileManager removeItemAtURL:legacyDatabaseURL error:nil];
        }
    }
    
    
    if ([fileManager fileExistsAtPath:databaseURL.path])
    {
        NSURL *mom2 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 2" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
        NSURL *mom3 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 3" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
        NSManagedObjectModel *version2Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom2];
        NSManagedObjectModel *version3Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom3];
        
        if ([OTRDatabaseManager isManagedObjectModel:version2Model compatibleWithStoreAtUrl:databaseURL]) {
            [OTRDatabaseManager migrateLegacyStore:databaseURL destinationStore:databaseURL sourceModel:version2Model destinationModel:version3Model error:nil];
        }
        
        
        [MagicalRecord setShouldAutoCreateManagedObjectModel:NO];
        [MagicalRecord setDefaultModelNamed:@"ChatSecure.momd"];
        [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"ChatSecure.sqlite"];
        
         ////// Migrate core data to yapdatabase //////
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        
        NSArray *coreDataAccounts = [OTRManagedAccount MR_findAllInContext:context];
        
        NSMutableArray *accounts = [NSMutableArray array];
        [coreDataAccounts enumerateObjectsUsingBlock:^(OTRManagedAccount *account, NSUInteger idx, BOOL *stop) {
            OTRAccount *newAccount = [self accountWithCoreDataAccount:account];
            if (newAccount) {
                [accounts addObject:newAccount];
            }
        }];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [accounts enumerateObjectsUsingBlock:^(OTRAccount *account, NSUInteger idx, BOOL *stop) {
                [account saveWithTransaction:transaction];
            }];
        }];
        
        [[NSFileManager defaultManager] removeItemAtURL:databaseURL error:nil];
    }
    
    [OTRDatabaseManager deleteLegacyXMPPFiles];
}

- (OTRAccount *)accountWithCoreDataAccount:(OTRManagedAccount *)managedAccount
{
    NSDictionary *accountDictionary = [managedAccount propertiesDictionary];
    
    if ([accountDictionary[kOTRClassKey] isEqualToString:NSStringFromClass([OTRManagedOscarAccount class])]) {
        return nil;
    }
    
    OTRXMPPAccount *account = (OTRXMPPAccount *)[OTRAccount accountForAccountType:[self accountTypeWithCoreDataClass:accountDictionary[kOTRClassKey]]];
    
    account.username = accountDictionary[OTRManagedAccountAttributes.username];
    account.autologin = [accountDictionary[OTRManagedAccountAttributes.autologin] boolValue];
    account.rememberPassword = [accountDictionary[OTRManagedAccountAttributes.rememberPassword] boolValue];
    account.displayName = accountDictionary[OTRManagedAccountAttributes.displayName];
    account.domain = accountDictionary[OTRManagedXMPPAccountAttributes.domain];
    account.port = [accountDictionary[OTRManagedXMPPAccountAttributes.port] intValue];
    
    ////// transfer saved passwords //////
    
    if (account.accountType == OTRAccountTypeFacebook || account.accountType == OTRAccountTypeGoogleTalk) {
        NSError *error = nil;
        SSKeychainQuery * keychainQuery = [[SSKeychainQuery alloc] init];
        keychainQuery.service = kOTRServiceName;
        keychainQuery.account = accountDictionary[OTRManagedAccountAttributes.uniqueIdentifier];
        [keychainQuery fetch:&error];
        NSDictionary *dictionary = (NSDictionary *)keychainQuery.passwordObject;
        
        ((OTROAuthXMPPAccount *)account).oAuthTokenDictionary = dictionary;
    }
    else if (account.rememberPassword) {
        NSError *error = nil;
        NSString *password = [SSKeychain passwordForService:kOTRServiceName account:accountDictionary[OTRManagedAccountAttributes.uniqueIdentifier] error:&error];
        
        account.password = password;
    }
    
    return account;
}

- (OTRAccountType)accountTypeWithCoreDataClass:(NSString *)coreDataClass
{
    if ([coreDataClass isEqualToString:NSStringFromClass([OTRManagedXMPPAccount class])]) {
        return OTRAccountTypeJabber;
    }
    else if ([coreDataClass isEqualToString:NSStringFromClass([OTRManagedGoogleAccount class])]) {
        return OTRAccountTypeGoogleTalk;
    }
    else if ([coreDataClass isEqualToString:NSStringFromClass([OTRManagedFacebookAccount class])]) {
        return OTRAccountTypeFacebook;
    }
    return OTRAccountTypeNone;
}

- (BOOL)setupYapDatabaseWithName:(NSString *)name
{
    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Fail;
    options.passphraseBlock = ^{
        NSString *passphrase = [self databasePassphrase];
        if (!passphrase.length) {
            [NSException raise:@"Must have passphrase of length > 0" format:@"password length is %d.", (int)passphrase.length];
        }
        return passphrase;
    };
    
    NSString *databaseDirectory = [[self class] yapDatabaseDirectory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:databaseDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:databaseDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *databasePath = [[self class] yapDatabasePathWithName:name];
    
    self.database = [[YapDatabase alloc] initWithPath:databasePath
                                     objectSerializer:NULL
                                   objectDeserializer:NULL
                                   metadataSerializer:NULL
                                 metadataDeserializer:NULL
                                      objectSanitizer:NULL
                                    metadataSanitizer:NULL
                                              options:options];
    
    self.database.defaultObjectPolicy = YapDatabasePolicyShare;
    self.database.defaultObjectCacheLimit = 1000;
    
    self.readOnlyDatabaseConnection = [self.database newConnection];
    self.readOnlyDatabaseConnection.name = @"readOnlyDatabaseConnection";
    
    self.readWriteDatabaseConnection = [self.database newConnection];
    self.readWriteDatabaseConnection.name = @"readWriteDatabaseConnection";
    
    
    ////// Register standard views////////
    YapDatabaseRelationship *databaseRelationship = [[YapDatabaseRelationship alloc] init];
    BOOL success = [self.database registerExtension:databaseRelationship withName:OTRYapDatabaseRelationshipName];
    if (success) success = [OTRDatabaseView registerAllAccountsDatabaseView];
    if (success) success = [OTRDatabaseView registerConversationDatabaseView];
    if (success) success = [OTRDatabaseView registerChatDatabaseView];
    if (success) success = [OTRDatabaseView registerBuddyDatabaseView];
    if (success) success = [OTRDatabaseView registerBuddyNameSearchDatabaseView];
    if (success) success = [OTRDatabaseView registerAllBuddiesDatabaseView];
    if (success) success = [OTRDatabaseView registerAllSubscriptionRequestsView];
    if (success) success = [OTRDatabaseView registerUnreadMessagesView];
    if (success) success = [OTRDatabaseView registerPushView];
    if (success) success = [self setupSecondaryIndexes];
    
    
    
    //Enumerate all files in yap database directory and exclude from backup
    if (success) {
        NSError *error = nil;
        NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:databaseDirectory];
        id file;
        while ((file = [directoryEnumerator nextObject]) && success && !error) {
            if([file isKindOfClass:[NSString class]]) {
                NSString *fileName = file;
                NSURL *url = [NSURL fileURLWithPath:[databaseDirectory stringByAppendingPathComponent:fileName]];
                success = [url setResourceValue: @(YES) forKey: NSURLIsExcludedFromBackupKey error: &error];
            }
        }
    }
    
    if (self.database && success) {
        return YES;
    }
    else {
        return NO;
    }
}

- (YapDatabaseConnection *)newConnection
{
    return [self.database newConnection];
}

- (BOOL)setupSecondaryIndexes
{
    YapDatabaseSecondaryIndexSetup *setup = [[YapDatabaseSecondaryIndexSetup alloc] init];
    [setup addColumn:OTRYapDatabseMessageIdSecondaryIndex withType:YapDatabaseSecondaryIndexTypeText];
    
    YapDatabaseSecondaryIndexHandler *indexHandler = [YapDatabaseSecondaryIndexHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRMessage class]])
        {
            OTRMessage *message = (OTRMessage *)object;
            
            if ([message.messageId length]) {
                [dict setObject:message.messageId forKey:OTRYapDatabseMessageIdSecondaryIndex];
            }
        }
    }];
    
    YapDatabaseSecondaryIndex *secondaryIndex = [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:indexHandler];
    
    return [self.database registerExtension:secondaryIndex withName:OTRYapDatabseMessageIdSecondaryIndexExtension];
    
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

+ (BOOL)migrateLegacyStore:(NSURL *)storeURL destinationStore:(NSURL*)destinationURL {
    NSURL *mom1 = [[NSBundle mainBundle] URLForResource:@"ChatSecure" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
    NSURL *mom2 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 2" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
    NSManagedObjectModel *version1Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom1];
    NSManagedObjectModel *version2Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom2];
    NSArray *xmppMoms = [self legacyXMPPModels];
    NSUInteger modelCount = xmppMoms.count + 1;
    NSMutableArray *inputModels = [NSMutableArray arrayWithCapacity:modelCount];
    NSMutableArray *outputModels = [NSMutableArray arrayWithCapacity:modelCount];
    [inputModels addObjectsFromArray:xmppMoms];
    [outputModels addObjectsFromArray:xmppMoms];
    [inputModels addObject:version1Model];
    [outputModels addObject:version2Model];
    
    NSManagedObjectModel *inputModel = [NSManagedObjectModel modelByMergingModels:inputModels];
    
    return [self migrateLegacyStore:storeURL destinationStore:destinationURL sourceModel:inputModel destinationModel:version2Model error:NULL];
}
+ (BOOL)isManagedObjectModel:(NSManagedObjectModel *)managedObjectModel compatibleWithStoreAtUrl:(NSURL *)storeUrl {
    
    NSError * error = nil;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeUrl error:&error];
    if (!sourceMetadata) {
        return NO;
    }
    return [managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
}

+ (NSArray*) legacyXMPPModels {
    NSURL *xmppRosterURL = [[NSBundle mainBundle] URLForResource:@"XMPPRoster" withExtension:@"mom"];
    NSURL *xmppCapsURL = [[NSBundle mainBundle] URLForResource:@"XMPPCapabilities" withExtension:@"mom"];
    NSURL *xmppRoomURL = [[NSBundle mainBundle] URLForResource:@"XMPPRoom" withExtension:@"mom" subdirectory:@"XMPPRoom.momd"];
    NSURL *xmppRoomHybridURL = [[NSBundle mainBundle] URLForResource:@"XMPPRoomHybrid" withExtension:@"mom" subdirectory:@"XMPPRoomHybrid.momd"];
    NSURL *xmppvCardURL = [[NSBundle mainBundle] URLForResource:@"XMPPvCard" withExtension:@"mom" subdirectory:@"XMPPvCard.momd"];
    NSURL *xmppMessageArchivingURL = [[NSBundle mainBundle] URLForResource:@"XMPPMessageArchiving" withExtension:@"mom" subdirectory:@"XMPPMessageArchiving.momd"];
    NSArray *momUrls = @[xmppRosterURL, xmppCapsURL, xmppRoomURL, xmppRoomHybridURL, xmppvCardURL, xmppMessageArchivingURL];
    NSMutableArray *xmppMoms = [NSMutableArray arrayWithCapacity:momUrls.count];
    for (NSURL *url in momUrls) {
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
        [xmppMoms addObject:model];
    }
    return xmppMoms;
}

+ (BOOL)migrateLegacyStore:(NSURL *)storeURL destinationStore:(NSURL *)dstStoreURL sourceModel:(NSManagedObjectModel*)sourceModel destinationModel:(NSManagedObjectModel*)destinationModel error:(NSError **)outError {
    
    // Try to get an inferred mapping model.
    NSMappingModel *mappingModel =
    [NSMappingModel inferredMappingModelForSourceModel:sourceModel
                                      destinationModel:destinationModel error:outError];
    
    // If Core Data cannot create an inferred mapping model, return NO.
    if (!mappingModel) {
        return NO;
    }
    
    // Create a migration manager to perform the migration.
    NSMigrationManager *manager = [[NSMigrationManager alloc]
                                   initWithSourceModel:sourceModel destinationModel:destinationModel];
    
    BOOL success = [manager migrateStoreFromURL:storeURL type:NSSQLiteStoreType
                                        options:nil withMappingModel:mappingModel toDestinationURL:dstStoreURL
                                destinationType:NSSQLiteStoreType destinationOptions:nil error:outError];
    
    return success;
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
        [SSKeychain setPassword:passphrase forService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName error:error];
    } else {
        [SSKeychain deletePasswordForService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName];
        self.inMemoryPassphrase = passphrase;
    }
}

- (BOOL)changePassphrase:(NSString*)newPassphrase remember:(BOOL)rememeber {
    // Temporarily grab old password in case change fails
    NSString *oldPassword = [self databasePassphrase];
    NSError *error = nil;
    [self setDatabasePassphrase:newPassphrase remember:rememeber error:&error];
    
    BOOL success = [self.database changeEncryptionKey];
    if (!success) {
        [self setDatabasePassphrase:oldPassword remember:rememeber error:&error];
    }
    return success;
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
        return [SSKeychain passwordForService:kOTRServiceName account:OTRYapDatabasePassphraseAccountName];
    }
    
}

#pragma - mark Singlton Methodd

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
