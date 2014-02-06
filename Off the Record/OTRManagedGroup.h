#import "_OTRManagedGroup.h"

@interface OTRManagedGroup : _OTRManagedGroup {}

+ (OTRManagedGroup *)fetchOrCreateWithName:(NSString *)name inContext:(NSManagedObjectContext *)context;


@end
