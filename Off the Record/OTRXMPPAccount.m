//
//  OTRXMPPAccount.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPAccount.h"
#import "OTRXMPPManager.h"
#import "Strings.h"
#import "OTRConstants.h"

const struct OTRXMPPAccountAttributes OTRXMPPAccountAttributes = {
	.domain = @"domain",
	.port = @"port",
	.resource = @"resource"
};

static NSUInteger const OTRDefaultPortNumber = 5222;

@implementation OTRXMPPAccount

- (id)init
{
    if (self = [super init]) {
        self.port = [OTRXMPPAccount defaultPort];
        self.resource = [OTRXMPPAccount newResource];
    }
    return self;
}

- (OTRProtocolType)protocolType
{
    return OTRProtocolTypeXMPP;
}

- (NSString *)protocolTypeString
{
    return @"xmpp";
}

- (UIImage *)accountImage
{
    return [UIImage imageNamed:OTRXMPPImageName];
}
- (NSString *)accountDisplayName
{
    return JABBER_STRING;
}

- (Class)protocolClass {
    return [OTRXMPPManager class];
}


#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)decoder // NSCoding deserialization
{
    if (self = [super initWithCoder:decoder]) {
        self.domain = [decoder decodeObjectForKey:OTRXMPPAccountAttributes.domain];
        self.resource = [decoder decodeObjectForKey:OTRXMPPAccountAttributes.resource];
        self.port = [decoder decodeIntForKey:OTRXMPPAccountAttributes.port];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder // NSCoding serialization
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeInt:self.port forKey:OTRXMPPAccountAttributes.port];
    [encoder encodeObject:self.domain forKey:OTRXMPPAccountAttributes.domain];
    [encoder encodeObject:self.resource forKey:OTRXMPPAccountAttributes.resource];
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OTRXMPPAccount *copy = [super copyWithZone:zone];
    copy.port = self.port;
    copy.domain = [self.domain copyWithZone:zone];
    copy.resource = [self.resource copyWithZone:zone];
    
    return copy;
}

#pragma - mark Class Methods


+ (NSString *)collection
{
    return NSStringFromClass([OTRAccount class]);
}

+ (int)defaultPort
{
    return OTRDefaultPortNumber;
}

+ (NSString * )newResource
{
    int r = arc4random() % 99999;
    return [NSString stringWithFormat:@"%@%d",kOTRXMPPResource,r];
}


@end
