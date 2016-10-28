//
//  OTRDatabaseManager.h
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@import YapDatabase;

#import "OTRMediaServer.h"
#import "OTRMediaFileManager.h"

@class MessageQueueHandler, YapTaskQueueBroker;

extern NSString *const OTRYapDatabseMessageIdSecondaryIndexColumnName;
extern NSString *const OTRYapDatabseRoomOccupantJIdSecondaryIndexColumnName;
extern NSString *const OTRYapDatabaseUnreadMessageSecondaryIndexColumnName;
extern NSString *const OTRYapDatabaseSignalSessionSecondaryIndexColumnName;
extern NSString *const OTRYapDatabaseSignalPreKeyIdSecondaryIndexColumnName;
extern NSString *const OTRYapDatabaseSignalPreKeyAccountKeySecondaryIndexColumnName;

@interface OTRDatabaseManager : NSObject

@property (nonatomic, readonly) YapDatabase *database;
@property (nonatomic, strong) OTRMediaServer *mediaServer;
@property (nonatomic, readonly) YapDatabaseConnection *readOnlyDatabaseConnection;
@property (nonatomic, readonly) YapDatabaseConnection *readWriteDatabaseConnection;

@property (nonatomic, readonly) MessageQueueHandler *messageQueueHandler;
@property (nonatomic, readonly) YapTaskQueueBroker *messageQueueBroker;


/**
 This method sets up both the yap database and IOCipher media storage
 Before this method is called the passphrase needs to be set.
 
 @param databaseName the name of the database. The media storage with be databaseName-media
 @return whether setup was successful
 */
- (BOOL)setupDatabaseWithName:(NSString*)databaseName;
- (BOOL)setupDatabaseWithName:(NSString*)databaseName withMediaStorage:(BOOL)withMediaStorage;

- (YapDatabaseConnection *)newConnection;

- (void)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error;


- (BOOL)hasPassphrase;

- (NSString *)databasePassphrase;

+ (BOOL)existsYapDatabase;

+ (NSString *)yapDatabaseDirectory;
+ (NSString *)yapDatabasePathWithName:(NSString *)name;


+ (instancetype)sharedInstance;

@end
