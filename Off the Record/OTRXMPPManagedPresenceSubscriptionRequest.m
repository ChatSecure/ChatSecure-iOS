#import "OTRXMPPManagedPresenceSubscriptionRequest.h"


@interface OTRXMPPManagedPresenceSubscriptionRequest ()

// Private interface goes here.

@end


@implementation OTRXMPPManagedPresenceSubscriptionRequest


+(OTRXMPPManagedPresenceSubscriptionRequest *)fetchOrCreateWith:(NSString *)jid account:(OTRManagedXMPPAccount *)account
{
    NSPredicate * jidPredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRXMPPManagedPresenceSubscriptionRequestAttributes.jid,jid];
    NSPredicate * accountPredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRXMPPManagedPresenceSubscriptionRequestRelationships.xmppAccount,account];
    NSPredicate * predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[jidPredicate,accountPredicate]];
    NSArray * resultsArray = [OTRXMPPManagedPresenceSubscriptionRequest MR_findAllWithPredicate:predicate];
    
    if ([resultsArray count]) {
        return [resultsArray lastObject];
    }
    else{
        OTRXMPPManagedPresenceSubscriptionRequest * newRequest = [OTRXMPPManagedPresenceSubscriptionRequest MR_createEntity];
        newRequest.jid = jid;
        newRequest.xmppAccount = account;
        return newRequest;
    }
}

@end
