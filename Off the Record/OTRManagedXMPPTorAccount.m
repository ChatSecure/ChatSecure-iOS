#import "OTRManagedXMPPTorAccount.h"


@interface OTRManagedXMPPTorAccount ()

// Private interface goes here.

@end


@implementation OTRManagedXMPPTorAccount

- (OTRAccountType)accountType {
    return OTRAccountTypeXMPPTor;
}

@end
