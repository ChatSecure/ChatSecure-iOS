#import "_OTRXMPPManagedPresenceSubscriptionRequest.h"

@interface OTRXMPPManagedPresenceSubscriptionRequest : _OTRXMPPManagedPresenceSubscriptionRequest {}

+ (OTRXMPPManagedPresenceSubscriptionRequest *)fetchOrCreateWith:(NSString *)jid account:(OTRManagedXMPPAccount *)account inContext:(NSManagedObjectContext *)context;

@end
