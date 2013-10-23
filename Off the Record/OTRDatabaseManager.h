//
//  OTRDatabaseManager.h
//  Off the Record
//
//  Created by Christopher Ballinger on 10/17/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRDatabaseManager : NSObject

+ (BOOL) setupDatabaseWithName:(NSString*)databaseName;

@end
