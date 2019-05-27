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

/// User interface / synchronous main-thread reads only!
@property (nonatomic, readonly, nullable) YapDatabaseConnection *uiConnection;
/// Background / async reads only! Not for use in main thread / UI code.
@property (nonatomic, readonly, nullable) YapDatabaseConnection *readConnection;
/// Background writes only! Never use this synchronously from the main thread!
@property (nonatomic, readonly, nullable) YapDatabaseConnection *writeConnection;

/// This is only to be used by the YapViewHandler for main thread reads only!
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

- (BOOL)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError *_Nullable*)error;


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
