#import "OTRManagedGroup.h"


@interface OTRManagedGroup ()

// Private interface goes here.

@end


@implementation OTRManagedGroup

+(OTRManagedGroup *)fetchOrCreateWithName:(NSString *)name
{
    OTRManagedGroup * group = nil;
    
    group = [OTRManagedGroup MR_findFirstByAttribute:OTRManagedGroupAttributes.name withValue:name];
    
    if (!group) {
        group = [OTRManagedGroup MR_createEntity];
        NSError * error = nil;
        [[NSManagedObjectContext MR_contextForCurrentThread] obtainPermanentIDsForObjects:@[group] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for Group: %@",error);
        }
        group.name = name;
        
    }
    
    return group;
}
+(OTRManagedGroup *)fetchOrCreateWithName:(NSString *)name inContext:(NSManagedObjectContext *)context
{
    OTRManagedGroup * group = nil;
    
    group = [OTRManagedGroup MR_findFirstByAttribute:OTRManagedGroupAttributes.name withValue:name inContext:context];
    
    if (!group) {
        group = [OTRManagedGroup MR_createInContext:context];
        NSError * error = nil;
        [[NSManagedObjectContext MR_contextForCurrentThread] obtainPermanentIDsForObjects:@[group] error:&error];
        if (error) {
            DDLogError(@"Error obtaining permanent ID for Group: %@",error);
        }
        group.name = name;
        
    }
    
    return group;
}

@end
