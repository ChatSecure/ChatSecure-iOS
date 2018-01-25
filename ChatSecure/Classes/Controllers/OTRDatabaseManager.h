//
//  OTRDatabaseManager.h
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

@import Foundation;

@import YapDatabase;
@import YapTaskQueue;

#import "OTRMediaServer.h"
#import "OTRMediaFileManager.h"

@class MessageQueueHandler;

NS_ASSUME_NONNULL_BEGIN

@interface OTRDatabaseManager : NSObject

@property (nonatomic, readonly, nullable) YapDatabase *database;
@property (nonatomic, strong, nullable) OTRMediaServer *mediaServer;
@property (nonatomic, readonly, nullable) YapDatabaseConnection *readOnlyDatabaseConnection;
@property (nonatomic, readonly, nullable) YapDatabaseConnection *readWriteDatabaseConnection;

@property (nonatomic, readonly, nullable) YapDatabaseConnection *longLivedReadOnlyConnection;

@property (nonatomic, readonly, nullable) MessageQueueHandler *messageQueueHandler;


/**
 This method sets up both the yap database and IOCipher media storage
 Before this method is called the passphrase needs to be set.
 
 @param databaseName the name of the database. The media storage with be databaseName-media
 @return whether setup was successful
 */
- (BOOL)setupDatabaseWithName:(NSString*)databaseName;
- (BOOL)setupDatabaseWithName:(NSString*)databaseName withMediaStorage:(BOOL)withMediaStorage;
- (BOOL)setupDatabaseWithName:(NSString*)databaseName
                    directory:(nullable NSString*)directory
                  withMediaStorage:(BOOL)withMediaStorage;

- (nullable YapDatabaseConnection *)newConnection;

- (void)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError *_Nullable*)error;


- (BOOL)hasPassphrase;

- (nullable NSString *)databasePassphrase;

/** Checks for database at default path */
+ (BOOL)existsYapDatabase;

/** directory containing sqlite and WAL files. Will be nil until setupDatabaseWithName: is called.  */
@property (nonatomic, strong, readonly, nullable) NSString *databaseDirectory;
+ (NSString *)defaultYapDatabaseDirectory;
+ (NSString *)defaultYapDatabasePathWithName:(NSString *_Nullable)name;

+ (instancetype)sharedInstance;
@property (class, nonatomic, readonly) OTRDatabaseManager *shared;

NS_ASSUME_NONNULL_END

@end
