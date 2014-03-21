#import "OTRManagedXMPPTorAccount.h"

#import "OTRXMPPTorManager.h"
#import "Strings.h"


@interface OTRManagedXMPPTorAccount ()

// Private interface goes here.

@end


@implementation OTRManagedXMPPTorAccount

- (OTRAccountType)accountType {
    return OTRAccountTypeXMPPTor;
}

-(NSString *)providerName
{
    return XMPP_TOR_STRING;
}

-(Class)protocolClass
{
    return [OTRXMPPTorManager class];
}

-(UIImage *)accountImage
{
    return [UIImage imageNamed:OTRXMPPTorImageName];
}

@end
