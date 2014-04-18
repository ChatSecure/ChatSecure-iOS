// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRPushAccount.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedAccount.h"

extern const struct OTRPushAccountAttributes {
} OTRPushAccountAttributes;

extern const struct OTRPushAccountRelationships {
} OTRPushAccountRelationships;

extern const struct OTRPushAccountFetchedProperties {
} OTRPushAccountFetchedProperties;



@interface OTRPushAccountID : NSManagedObjectID {}
@end

@interface _OTRPushAccount : OTRManagedAccount {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRPushAccountID*)objectID;






@end

@interface _OTRPushAccount (CoreDataGeneratedAccessors)

@end

@interface _OTRPushAccount (CoreDataGeneratedPrimitiveAccessors)


@end
