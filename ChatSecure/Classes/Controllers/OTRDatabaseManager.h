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

extern NSString *const OTRYapDatabaseRelationshipName;
extern NSString *const OTRYapDatabseMessageIdSecondaryIndex;
extern NSString *const OTRYapDatabseMessageIdSecondaryIndexExtension;

@interface OTRDatabaseManager : NSObject

@property (nonatomic, readonly) YapDatabase *database;
@property (nonatomic, strong) OTRMediaServer *mediaServer;
@property (nonatomic, readonly) YapDatabaseConnection *readOnlyDatabaseConnection;
@property (nonatomic, readonly) YapDatabaseConnection *readWriteDatabaseConnection;


/**
 This method sets up both the yap database and IOCipher media storage
 Before this method is called the passphrase needs to be set.
 
 @param databaseName the name of the database. The media storage with be databaseName-media
 @return whether setup was successful
 */
- (BOOL)setupDatabaseWithName:(NSString*)databaseName;

- (YapDatabaseConnection *)newConnection;

- (void)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error;
/** This only works after calling setDatabasePassphrase */
- (BOOL)changePassphrase:(NSString*)newPassphrase remember:(BOOL)rememeber;


- (BOOL)hasPassphrase;

- (NSString *)databasePassphrase;

+ (BOOL)existsYapDatabase;

+ (NSString *)yapDatabasePathWithName:(NSString *)name;

+ (instancetype)sharedInstance;

@end
