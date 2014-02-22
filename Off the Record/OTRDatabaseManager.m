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

+ (BOOL) setupDatabaseWithName:(NSString*)databaseName {
    NSString *legacyDatabaseName = @"db.sqlite";
    NSURL * legacyDatabaseURL = [NSPersistentStore MR_urlForStoreName:legacyDatabaseName];
    
    
    
    NSURL * databaseURL = [NSPersistentStore MR_urlForStoreName:databaseName];
    
    //[self copyTestDatabaseToDestination:databaseURL];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:legacyDatabaseURL.path]) {
        // migrate store
        if([self migrateLegacyStore:legacyDatabaseURL destinationStore:databaseURL]) {
            [fileManager removeItemAtURL:legacyDatabaseURL error:nil];
        }
    }
    
    NSURL *mom2 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 2" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
    NSURL *mom3 = [[NSBundle mainBundle] URLForResource:@"ChatSecure 3" withExtension:@"mom" subdirectory:@"ChatSecure.momd"];
    NSManagedObjectModel *version2Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom2];
    NSManagedObjectModel *version3Model = [[NSManagedObjectModel alloc] initWithContentsOfURL:mom3];
    
    if ([self isManagedObjectModel:version2Model compatibleWithStoreAtUrl:databaseURL]) {
        [self migrateAccountsForManagedObjectModel:version2Model toManagedObjectModel:version3Model withStoreUrl:databaseURL];
    }
    
    
    [MagicalRecord setShouldAutoCreateManagedObjectModel:NO];
    [MagicalRecord setDefaultModelNamed:@"ChatSecure.momd"];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:databaseName];
    
    [OTREncryptionManager setFileProtection:NSFileProtectionCompleteUntilFirstUserAuthentication path:databaseURL.path];
    [OTREncryptionManager addSkipBackupAttributeToItemAtURL:databaseURL];
    
    [self deleteLegacyXMPPFiles];
    
    return YES;
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

+ (void)migrateAccountsForManagedObjectModel:(NSManagedObjectModel *)originalModel toManagedObjectModel:(NSManagedObjectModel *)finalObjectModel withStoreUrl:(NSURL *)storeUrl {
    
   
    
    
    NSError * error = nil;
    NSDictionary * options = @{NSMigratePersistentStoresAutomaticallyOption:@YES,
                              NSInferMappingModelAutomaticallyOption:@YES,
                              NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}
                              };
    NSPersistentStoreCoordinator * storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:originalModel];
    [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];
    
    //check if really matches (not sure if it really works
    //doesn't seem to fail if done here
    if (![self isManagedObjectModel:originalModel compatibleWithStoreAtUrl:storeUrl]) {
        return;
    }
    
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setPersistentStoreCoordinator:storeCoordinator];
    
    __block NSArray * results;
    [context performBlockAndWait:^{
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OTRManagedAccount"
                                                             inManagedObjectContext:context];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        results = [context executeFetchRequest:request error:nil];
    }];
    
    
    NSMutableArray * allAccountDictionaries = [NSMutableArray array];
    
    [results enumerateObjectsUsingBlock:^(OTRManagedAccount * account, NSUInteger idx, BOOL *stop) {
        [allAccountDictionaries addObject:[account dictionaryRepresentation]];
    }];
    
    
    [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:&error];
    
    
    storeCoordinator =[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:finalObjectModel];
    [storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setPersistentStoreCoordinator:storeCoordinator];
    
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:storeCoordinator];
    [NSManagedObjectContext MR_initializeDefaultContextWithCoordinator:storeCoordinator];
    
    [allAccountDictionaries enumerateObjectsUsingBlock:^(NSDictionary * accountDictionary, NSUInteger idx, BOOL *stop) {
        [OTRManagedAccount createWithDictionary:accountDictionary forContext:context];
    }];
    
    [context save:&error];
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

@end
