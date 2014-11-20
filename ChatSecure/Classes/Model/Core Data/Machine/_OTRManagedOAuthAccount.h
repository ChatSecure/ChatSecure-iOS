// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedOAuthAccount.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedXMPPAccount.h"

@interface OTRManagedOAuthAccountID : OTRManagedXMPPAccountID {}
@end

@interface _OTRManagedOAuthAccount : OTRManagedXMPPAccount {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) OTRManagedOAuthAccountID* objectID;

@end

@interface _OTRManagedOAuthAccount (CoreDataGeneratedPrimitiveAccessors)

@end
