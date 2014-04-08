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

NSString *const OTRUIDatabaseConnectionDidUpdateNotification = @"OTRUIDatabaseConnectionDidUpdateNotification";
NSString *const OTRUIDatabaseConnectionWillUpdateNotification = @"OTRUIDatabaseConnectionWillUpdateNotification";
NSString *const OTRYapDatabaseRelationshipName = @"OTRYapDatabaseRelationshipName";

@interface OTRDatabaseManager ()

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *mainThreadReadOnlyDatabaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *readWriteDatabaseConnection;

@end

@implementation OTRDatabaseManager

+ (void) copyTestDatabaseToDestination:(NSURL*)destinationURL {
    NSURL *testDBURL = [[NSBundle mainBundle] URLForResource:@"ChatSecure" withExtension:@"sqlite"];
    NSString *destinationPath = destinationURL.path;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    NSString *containingDirectory = [destinationPath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:containingDirectory]) {
        [fileManager createDirectoryAtPath:containingDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            DDLogError(@"Error creating folder for test DB %@", error.userInfo);
        }
    }
    
    if ([fileManager fileExistsAtPath:destinationPath]) {
        [fileManager removeItemAtPath:destinationPath error:&error];
        if (error) {
            DDLogError(@"Error removing old test db: %@", error.userInfo);
        }
    }
    
    [fileManager copyItemAtURL:testDBURL toURL:destinationURL error:&error];
    if (error) {
        DDLogError(@"error copying test database: %@", error.userInfo);
    }
}

- (BOOL) setupDatabaseWithName:(NSString*)databaseName {
    NSString *legacyDatabaseName = @"db.sqlite";
    NSURL * legacyDatabaseURL = [NSPersistentStore MR_urlForStoreName:legacyDatabaseName];

    NSURL * databaseURL = [NSPersistentStore MR_urlForStoreName:databaseName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:legacyDatabaseURL.path]) {
        // migrate store
        if([OTRDatabaseManager migrateLegacyStore:legacyDatabaseURL destinationStore:databaseURL]) {
            [fileManager removeItemAtURL:legacyDatabaseURL error:nil];
        }
    }
    
    NSURL *mom2 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 2" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
    NSURL *mom3 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 3" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
    NSURL *mom4 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 4" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
    NSManagedObjectModel *version2Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom2];
    NSManagedObjectModel *version3Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom3];
    NSManagedObjectModel *version4Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom4];
    
    if ([OTRDatabaseManager isManagedObjectModel:version2Model compatibleWithStoreAtUrl:databaseURL]) {
        
    }
    else if ([OTRDatabaseManager isManagedObjectModel:version3Model compatibleWithStoreAtUrl:databaseURL]) {
        
    }
    else if ([OTRDatabaseManager isManagedObjectModel:version4Model compatibleWithStoreAtUrl:databaseURL]) {
        
    }
    
    
    [MagicalRecord setShouldAutoCreateManagedObjectModel:NO];
    [MagicalRecord setDefaultModelNamed:@"ChatSecure.momd"];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:databaseName];
    
    [OTREncryptionManager setFileProtection:NSFileProtectionCompleteUntilFirstUserAuthentication path:databaseURL.path];
    [OTREncryptionManager addSkipBackupAttributeToItemAtURL:databaseURL];
    
    [OTRDatabaseManager deleteLegacyXMPPFiles];
    
    YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
    options.corruptAction = YapDatabaseCorruptAction_Delete;
//    options.passphraseBlock = ^{
//        // You can also do things like fetch from the keychain in here
//        return @"not a secure password";
//    };
    
    
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    NSString *directory = [applicationSupportDirectory stringByAppendingPathComponent:applicationName];
    NSString *databasePath = [directory stringByAppendingPathComponent:@"test.sqlite"];
    
    self.database = [[YapDatabase alloc] initWithPath:databasePath
                                objectSerializer:NULL
                              objectDeserializer:NULL
                              metadataSerializer:NULL
                            metadataDeserializer:NULL
                                 objectSanitizer:NULL
                               metadataSanitizer:NULL
                                         options:options];
    
    self.mainThreadReadOnlyDatabaseConnection = [self.database newConnection];
    self.mainThreadReadOnlyDatabaseConnection.objectCacheLimit = 500;
    self.mainThreadReadOnlyDatabaseConnection.metadataCacheLimit = 500;
    self.mainThreadReadOnlyDatabaseConnection.name = @"mainThreadReadOnlyDatabaseConnection";
    
    self.readWriteDatabaseConnection = [self.database newConnection];
    self.readWriteDatabaseConnection.objectCacheLimit = 200;
    self.readWriteDatabaseConnection.metadataCacheLimit = 200;
    self.readWriteDatabaseConnection.name = @"readWriteDatabaseConnection";
    
    [self.mainThreadReadOnlyDatabaseConnection enableExceptionsForImplicitlyEndingLongLivedReadTransaction];
    [self.mainThreadReadOnlyDatabaseConnection beginLongLivedReadTransaction];
    
    
    ////// Register standard views////////
    YapDatabaseRelationship *databaseRelationship = [[YapDatabaseRelationship alloc] init];
    [self.database registerExtension:databaseRelationship withName:OTRYapDatabaseRelationshipName];
    [OTRDatabaseView registerAllAccountsDatabaseView];
    [OTRDatabaseView registerConversationDatabaseView];
    [OTRDatabaseView registerChatDatabaseView];
    [OTRDatabaseView registerBuddyDatabaseView];
    BOOL result = [OTRDatabaseView registerBuddyNameSearchDatabaseView];
    [OTRDatabaseView registerAllBuddiesDatabaseView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.database];
    
    
    
    
    if (self.database) {
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

- (void)yapDatabaseModified:(NSNotification *)ignored
{
    // Notify observers we're about to update the database connection
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OTRUIDatabaseConnectionWillUpdateNotification object:self];
    
    // Move uiDatabaseConnection to the latest commit.
    // Do so atomically, and fetch all the notifications for each commit we jump.
    
    NSArray *notifications = [self.mainThreadReadOnlyDatabaseConnection beginLongLivedReadTransaction];
    
    // Notify observers that the uiDatabaseConnection was updated
    
    NSDictionary *userInfo = @{ @"notifications": notifications };
    [[NSNotificationCenter defaultCenter] postNotificationName:OTRUIDatabaseConnectionDidUpdateNotification
                                                        object:self
                                                      userInfo:userInfo];
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
