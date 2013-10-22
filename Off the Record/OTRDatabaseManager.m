//
//  OTRDatabaseManager.m
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseManager.h"

@implementation OTRDatabaseManager

+ (void) copyTestDatabaseToDestination:(NSURL*)destinationURL {
    NSURL *testDBURL = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"sqlite"];
    NSString *destinationPath = destinationURL.path;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    NSString *containingDirectory = [destinationPath stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:containingDirectory]) {
        [fileManager createDirectoryAtPath:containingDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating folder for test DB %@", error.userInfo);
        }
    }
    
    if ([fileManager fileExistsAtPath:destinationPath]) {
        [fileManager removeItemAtPath:destinationPath error:&error];
        if (error) {
            NSLog(@"Error removing old test db: %@", error.userInfo);
        }
    }
    
    [fileManager copyItemAtURL:testDBURL toURL:destinationURL error:&error];
    if (error) {
        NSLog(@"error copying test database: %@", error.userInfo);
    }
}

+ (BOOL) setupDatabaseWithName:(NSString*)databaseName {
    NSString *legacyDatabaseName = @"db.sqlite";
    NSURL * legacyDatabaseURL = [NSPersistentStore MR_urlForStoreName:legacyDatabaseName];
    
    [self copyTestDatabaseToDestination:legacyDatabaseURL];
    
    NSURL * databaseURL = [NSPersistentStore MR_urlForStoreName:databaseName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:legacyDatabaseURL.path]) {
        // migrate store
        if([self migrateLegacyStore:legacyDatabaseURL destinationStore:databaseURL]) {
            [fileManager removeItemAtURL:legacyDatabaseURL error:nil];
        }
    }
    
    [MagicalRecord setupCoreDataStackWithStoreNamed:databaseName];
    
    [self setFileProtection:NSFileProtectionCompleteUnlessOpen path:databaseURL.path];
    
    return YES;
}

+ (void) setFileProtection:(NSString*)fileProtection path:(NSString*)path {
    NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:fileProtection forKey:NSFileProtectionKey];
    NSError * error = nil;
    
    if (![[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:path error:&error])
    {
        NSLog(@"error encrypting store: %@", error.userInfo);
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
    NSManagedObjectModel *outputModel = [NSManagedObjectModel modelByMergingModels:outputModels];
    
    return [self migrateLegacyStore:storeURL destinationStore:destinationURL sourceModel:inputModel destinationModel:outputModel error:NULL];
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
