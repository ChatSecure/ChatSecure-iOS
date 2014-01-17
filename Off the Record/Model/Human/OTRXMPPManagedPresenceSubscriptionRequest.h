#import "_OTRXMPPManagedPresenceSubscriptionRequest.h"

@interface OTRXMPPManagedPresenceSubscriptionRequest : _OTRXMPPManagedPresenceSubscriptionRequest {}
// Custom logic goes here.


+(OTRXMPPManagedPresenceSubscriptionRequest *)fetchOrCreateWith:(NSString *)jid account:(OTRManagedXMPPAccount *)account;

@end
