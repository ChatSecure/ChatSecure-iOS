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
        
    }
    
    return group;
}

@end
