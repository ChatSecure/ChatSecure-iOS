//
//  OTROscarAccount.m
//  Off the Record
//
//  Created by Christopher Ballinger on 8/9/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTROscarAccount.h"
#import "OTRProtocol.h"
#import "Strings.h"
#import "OTROscarManager.h"
#import "OTRConstants.h"

@implementation OTROscarAccount

- (id) init {
    if (self = [super initWithProtocol:kOTRProtocolTypeAIM]) {
        
    }
    return self;
}

- (NSString *) imageName {
    return kAIMImageName;
}

- (NSString *)providerName
{
    return AIM_STRING;
}

- (Class) protocolClass {
    return [OTROscarManager class];
}

@end
