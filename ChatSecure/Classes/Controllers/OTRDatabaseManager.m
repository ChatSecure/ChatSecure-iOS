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
#import "OTRDatabaseView.h"
#import <SSKeychain/SSKeychain.h>
#import "OTRConstants.h"

#import "OTRManagedOscarAccount.h"
#import "OTRXMPPAccount.h"
#import "OTRXMPPTorAccount.h"
#import "OTRManagedGoogleAccount.h"
#import "OTRManagedFacebookAccount.h"
#import "OTRGoogleOAuthXMPPAccount.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRMediaFileManager.h"
#import "IOCipher.h"
#import "NSFileManager+ChatSecure.h"

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
    BOOL success = NO;
    if ([self setupYapDatabaseWithName:databaseName] )
    {
        success = YES;
    }
    if (success) success = [self setupSecureMediaStorage];
    
    NSString *databaseDirectory = [OTRDatabaseManager yapDatabaseDirectory];
    //Enumerate all files in yap database directory and exclude from backup
    if (success) success = [[NSFileManager defaultManager] otr_excudeFromBackUpFilesInDirectory:databaseDirectory];
    //fix file protection on existing files
     if (success) success = [[NSFileManager defaultManager] otr_setFileProtection:NSFileProtectionCompleteUntilFirstUserAuthentication forFilesInDirectory:databaseDirectory];
    return success;
}

- (BOOL)setupSecureMediaStorage
{
    NSString *password = [self databasePassphrase];
    NSString *path = [OTRDatabaseManager yapDatabasePathWithName:nil];
    path = [path stringByAppendingPathComponent:@"ChatSecure-media.sqlite"];
    BOOL success = [[OTRMediaFileManager sharedInstance] setupWithPath:path password:password];
    
    self.mediaServer = [OTRMediaServer sharedInstance];
    NSError *error = nil;
    BOOL mediaServerStarted = [self.mediaServer startOnPort:8080 error:&error];
    if (!mediaServerStarted) {
        DDLogError(@"Error starting media server: %@",error);
    }
    return success;
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
    
    if (account.accountType == OTRAccountTypeGoogleTalk) {
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
    return OTRAccountTypeNone;
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
    if (success) success = [OTRDatabaseView registerBuddyNameSearchDatabaseView];
    if (success) success = [OTRDatabaseView registerAllBuddiesDatabaseView];
    if (success) success = [OTRDatabaseView registerAllSubscriptionRequestsView];
    if (success) success = [OTRDatabaseView registerUnreadMessagesView];
    if (success) success = [self setupSecondaryIndexes];
    
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
    
    BOOL success = [self.database rekeyDatabase];
    if (!success) {
        [self setDatabasePassphrase:oldPassword remember:rememeber error:&error];
    } else {
       success = [[OTRMediaFileManager sharedInstance].ioCipher changePassword:newPassphrase oldPassword:oldPassword];
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
