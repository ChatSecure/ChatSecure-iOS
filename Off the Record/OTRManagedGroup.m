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
        
        group.name = name;
        
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
        
    }
    
    return group;
}
+(OTRManagedGroup *)fetchOrCreateWithName:(NSString *)name inContext:(NSManagedObjectContext *)context
{
    OTRManagedGroup * group = nil;
    
    group = [OTRManagedGroup MR_findFirstByAttribute:OTRManagedGroupAttributes.name withValue:name inContext:context];
    
    if (!group) {
        group = [OTRManagedGroup MR_createInContext:context];
    
        group.name = name;
        
        [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    }
    
    return group;
}

@end
