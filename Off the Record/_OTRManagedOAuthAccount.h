// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedOAuthAccount.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedXMPPAccount.h"

extern const struct OTRManagedOAuthAccountAttributes {
} OTRManagedOAuthAccountAttributes;

extern const struct OTRManagedOAuthAccountRelationships {
} OTRManagedOAuthAccountRelationships;

extern const struct OTRManagedOAuthAccountFetchedProperties {
} OTRManagedOAuthAccountFetchedProperties;



@interface OTRManagedOAuthAccountID : NSManagedObjectID {}
@end

@interface _OTRManagedOAuthAccount : OTRManagedXMPPAccount {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedOAuthAccountID*)objectID;






@end

@interface _OTRManagedOAuthAccount (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedOAuthAccount (CoreDataGeneratedPrimitiveAccessors)


@end
