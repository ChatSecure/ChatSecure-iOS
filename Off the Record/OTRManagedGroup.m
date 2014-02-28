#import "OTRManagedGroup.h"
#import "OTRLog.h"

@interface OTRManagedGroup ()

// Private interface goes here.

@end


@implementation OTRManagedGroup


+(OTRManagedGroup *)fetchOrCreateWithName:(NSString *)name inContext:(NSManagedObjectContext *)context
{
    OTRManagedGroup * group = nil;
    
    group = [OTRManagedGroup MR_findFirstByAttribute:OTRManagedGroupAttributes.name withValue:name inContext:context];
    
    if (!group) {
        group = [OTRManagedGroup MR_createInContext:context];
        NSError *error = nil;
        [context obtainPermanentIDsForObjects:@[group] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for OTRManagedGroup: %@", error);
        }
        group.name = name;
    }
    return group;
}

@end
