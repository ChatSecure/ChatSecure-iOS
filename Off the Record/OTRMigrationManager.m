//
//  OTRMigrationManager.m
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRMigrationManager.h"

@implementation OTRMigrationManager

+ (BOOL)migrateStore:(NSURL *)storeURL toVersionTwoStore:(NSURL *)dstStoreURL sourceModel:(NSManagedObjectModel*)sourceModel destinationModel:(NSManagedObjectModel*)destinationModel error:(NSError **)outError {
    
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

+ (BOOL)compareManagedObjectModel:(NSManagedObjectModel*)pscModel withStoreURL: (NSURL *)storeURL {
    NSError *error = nil;
    
    // Get the entities & keys from the persistent store coordinator
    NSDictionary *pscEntities = [pscModel entitiesByName];
    NSSet *pscKeys = [NSSet setWithArray:[pscEntities allKeys]];
    //NSLog(@"psc model:%@", pscModel);
    //NSLog(@"psc keys:%@", pscKeys);
    NSLog(@"psc contains %d entities", [pscModel.entities count]);
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:pscModel];
    // Adding the journalling mode recommended by apple
    NSMutableDictionary *sqliteOptions = [NSMutableDictionary dictionary];
    [sqliteOptions setObject:@"WAL" forKey:@"journal_mode"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:NO], NSInferMappingModelAutomaticallyOption,
                             sqliteOptions, NSSQLitePragmasOption,
                             nil];
    [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    NSIncrementalStore *store = [[psc persistentStores] lastObject];
    // Get the entity hashes from the storeURL
    NSDictionary *storeMetadata = [psc metadataForPersistentStore:store];
    NSDictionary *storeHashes = [storeMetadata objectForKey:@"NSStoreModelVersionHashes"];
    //NSLog(@"store metadata:%@", sourceMetadata);
    NSLog(@"store URL:%@", storeURL);
    NSLog(@"store NSStoreUUID:%@", [storeMetadata objectForKey:@"NSStoreUUID"]);
    NSLog(@"store NSStoreType:%@", [storeMetadata objectForKey:@"NSStoreType"]);
    NSSet *storeKeys = [NSSet setWithArray:[storeHashes allKeys]];
    
    // Determine store entities that were added, removed, and in common (to/with psc)
    NSMutableSet *addedEntities = [NSMutableSet setWithSet:pscKeys];
    NSMutableSet *removedEntities = [NSMutableSet setWithSet:storeKeys];
    NSMutableSet *commonEntities = [NSMutableSet setWithSet:pscKeys];
    NSMutableSet *changedEntities = [NSMutableSet new];
    [addedEntities minusSet:storeKeys];
    [removedEntities minusSet:pscKeys];
    [commonEntities minusSet:removedEntities];
    [commonEntities minusSet:addedEntities];
    
    // Determine entities that have changed (with different hashes)
    [commonEntities enumerateObjectsUsingBlock:^(NSString *key, BOOL *stop) {
        NSData *storeHash = [storeHashes objectForKey:key];
        NSEntityDescription *pscDescrip = [pscEntities objectForKey:key];
        if ( ! [pscDescrip.versionHash isEqualToData:storeHash]) {
            if (storeHash != nil && pscDescrip.versionHash != nil) {
                [changedEntities addObject:key];
            }
        }
    }];
    
    // Remove changed entities from common list
    [commonEntities minusSet:changedEntities];
    
    if ([commonEntities count] > 0) {
        NSLog(@"Common entities:");
        [commonEntities enumerateObjectsUsingBlock:^(NSString *key, BOOL *stop) {
            NSData *storeHash = [storeHashes objectForKey:key];
            NSEntityDescription *pscDescrip = [pscEntities objectForKey:key];
            NSLog(@"\t%@:\t%@", key, pscDescrip.versionHash);
        }];
    }
    if ([changedEntities count] > 0) {
        NSLog(@"Changed entities:");
        [changedEntities enumerateObjectsUsingBlock:^(NSString *key, BOOL *stop) {
            NSData *storeHash = [storeHashes objectForKey:key];
            NSEntityDescription *pscDescrip = [pscEntities objectForKey:key];
            NSLog(@"\tpsc   %@:\t%@", key, pscDescrip.versionHash);
            NSLog(@"\tstore %@:\t%@", key, storeHash);
        }];
    }
    if ([addedEntities count] > 0) {
        NSLog(@"Added entities to psc model (not in store):");
        [addedEntities enumerateObjectsUsingBlock:^(NSString *key, BOOL *stop) {
            NSEntityDescription *pscDescrip = [pscEntities objectForKey:key];
            NSLog(@"\t%@:\t%@", key, pscDescrip.versionHash);
        }];
    }
    if ([removedEntities count] > 0) {
        NSLog(@"Removed entities from psc model (exist in store):");
        [removedEntities enumerateObjectsUsingBlock:^(NSString *key, BOOL *stop) {
            NSData *storeHash = [storeHashes objectForKey:key];
            NSLog(@"\t%@:\t%@", key, storeHash);
        }];
    }
    
    BOOL pscCompatibile = [pscModel isConfiguration:nil     compatibleWithStoreMetadata:storeMetadata];
    NSLog(@"Migration needed? %@", pscCompatibile?@"no":@"yes");
    
    return pscCompatibile;
}

@end
