//
//  OTRConvertAccount.h
//  Off the Record
//
//  Created by David on 1/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OTRConvertAccount : NSObject


-(BOOL)hasLegacyAccountSettings;
-(BOOL)convertAllLegacyAcountSettings;

@end
