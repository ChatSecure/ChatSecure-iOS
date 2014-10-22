//
//  OTRDatabaseManager.h
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YapDatabaseConnection.h"
#import "YapDatabase.h"
#import "YapDatabaseTransaction.h"

extern NSString *const OTRUIDatabaseConnectionDidUpdateNotification;
extern NSString *const OTRUIDatabaseConnectionWillUpdateNotification;
extern NSString *const OTRYapDatabaseRelationshipName;
extern NSString *const OTRYapDatabseMessageIdSecondaryIndex;
extern NSString *const OTRYapDatabseMessageIdSecondaryIndexExtension;

@interface OTRDatabaseManager : NSObject

@property (nonatomic, readonly) YapDatabase *database;
@property (nonatomic, readonly) YapDatabaseConnection *mainThreadReadOnlyDatabaseConnection;
@property (nonatomic, readonly) YapDatabaseConnection *readWriteDatabaseConnection;

- (BOOL)setupDatabaseWithName:(NSString*)databaseName;

- (YapDatabaseConnection *)newConnection;



- (void)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error;
- (BOOL)hasPassphrase;

+ (BOOL)existsYapDatabase;

+ (instancetype)sharedInstance;

@end
