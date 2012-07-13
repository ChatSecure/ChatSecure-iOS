//
//  OTRAccountsManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRAccount.h"

@interface OTRAccountsManager : NSObject

@property (nonatomic, retain) NSMutableDictionary *accountsDictionary;
@property (nonatomic, retain) NSMutableDictionary *reverseLookupDictionary;
@property (nonatomic, retain) NSArray *accountsArray;

- (void) addAccount:(OTRAccount*)account;
- (void) removeAccount:(OTRAccount*)account;

- (OTRAccount *) accountForProtocol:(NSString *)protocol accountName: (NSString *) accountName;

@end
