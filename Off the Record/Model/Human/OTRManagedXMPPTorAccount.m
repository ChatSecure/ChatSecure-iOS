#import "OTRManagedXMPPTorAccount.h"

#import "OTRXMPPTorManager.h"


@interface OTRManagedXMPPTorAccount ()

// Private interface goes here.

@end


@implementation OTRManagedXMPPTorAccount

- (OTRAccountType)accountType {
    return OTRAccountTypeXMPPTor;
}

-(Class)protocolClass
{
    return [OTRXMPPTorManager class];
}

-(NSString *)imageName
{
    return OTRXMPPTorImageName;
}

@end
