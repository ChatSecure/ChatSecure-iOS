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

extern NSString *const OTRYapDatabaseRelationshipName;
extern NSString *const OTRYapDatabseMessageIdSecondaryIndex;
extern NSString *const OTRYapDatabseMessageIdSecondaryIndexExtension;

@interface OTRDatabaseManager : NSObject

@property (nonatomic, readonly) YapDatabase *database;
@property (nonatomic, readonly) YapDatabaseConnection *readOnlyDatabaseConnection;
@property (nonatomic, readonly) YapDatabaseConnection *readWriteDatabaseConnection;

- (BOOL)setupDatabaseWithName:(NSString*)databaseName;

- (YapDatabaseConnection *)newConnection;

- (void)setDatabasePassphrase:(NSString *)passphrase remember:(BOOL)rememeber error:(NSError**)error;
/** This only works after calling setDatabasePassphrase */
- (BOOL)changePassphrase:(NSString*)newPassphrase remember:(BOOL)rememeber;


- (BOOL)hasPassphrase;

+ (BOOL)existsYapDatabase;

+ (NSString *)yapDatabasePathWithName:(NSString *)name;

+ (instancetype)sharedInstance;

@end
