//
//  OTRPushAccount.m
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRPushAccount.h"
#import "Strings.h"
#import "OTRPushManager.h"

@implementation OTRPushAccount

- (NSString *) imageName {
    return @"ipad.png";
}

- (NSString *)providerName
{
    return CHATSECURE_PUSH_STRING;
}

- (Class) protocolClass {
    return [OTRPushManager class];
}

@end
