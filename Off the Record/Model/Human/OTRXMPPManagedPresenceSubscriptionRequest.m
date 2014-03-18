#import "OTRXMPPManagedPresenceSubscriptionRequest.h"

#import "OTRManagedXMPPAccount.h"
#import "OTRLog.h"

@interface OTRXMPPManagedPresenceSubscriptionRequest ()

// Private interface goes here.

@end


@implementation OTRXMPPManagedPresenceSubscriptionRequest


+(OTRXMPPManagedPresenceSubscriptionRequest *)fetchOrCreateWith:(NSString *)jid account:(OTRManagedXMPPAccount *)account inContext:(NSManagedObjectContext *)context
{
    OTRManagedXMPPAccount *localAccount = [account MR_inContext:context];
    NSPredicate * jidPredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRXMPPManagedPresenceSubscriptionRequestAttributes.jid,jid];
    NSPredicate * accountPredicate = [NSPredicate predicateWithFormat:@"%K == %@",OTRXMPPManagedPresenceSubscriptionRequestRelationships.xmppAccount,localAccount];
    NSPredicate * predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[jidPredicate,accountPredicate]];
    NSArray * resultsArray = [OTRXMPPManagedPresenceSubscriptionRequest MR_findAllWithPredicate:predicate inContext:context];
    
    if ([resultsArray count]) {
        return [resultsArray firstObject];
    }
    else{
        OTRXMPPManagedPresenceSubscriptionRequest * newRequest = [OTRXMPPManagedPresenceSubscriptionRequest MR_createInContext:context];
        NSError *error = nil;
        [context obtainPermanentIDsForObjects:@[newRequest] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for subscription request: %@", error);
        }
        newRequest.jid = jid;
        newRequest.xmppAccount = localAccount;
        return newRequest;
    }
}

@end
