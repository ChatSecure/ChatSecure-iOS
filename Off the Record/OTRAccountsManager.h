//
//  OTRAccountsManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

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
