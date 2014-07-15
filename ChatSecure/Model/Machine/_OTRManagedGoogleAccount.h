// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedGoogleAccount.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedOAuthAccount.h"

extern const struct OTRManagedGoogleAccountAttributes {
} OTRManagedGoogleAccountAttributes;

extern const struct OTRManagedGoogleAccountRelationships {
} OTRManagedGoogleAccountRelationships;

extern const struct OTRManagedGoogleAccountFetchedProperties {
} OTRManagedGoogleAccountFetchedProperties;



@interface OTRManagedGoogleAccountID : NSManagedObjectID {}
@end

@interface _OTRManagedGoogleAccount : OTRManagedOAuthAccount {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedGoogleAccountID*)objectID;






@end

@interface _OTRManagedGoogleAccount (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedGoogleAccount (CoreDataGeneratedPrimitiveAccessors)


@end
