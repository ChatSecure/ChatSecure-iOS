// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedGoogleAccount.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedOAuthAccount.h"

@interface OTRManagedGoogleAccountID : OTRManagedOAuthAccountID {}
@end

@interface _OTRManagedGoogleAccount : OTRManagedOAuthAccount {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) OTRManagedGoogleAccountID* objectID;

@end

@interface _OTRManagedGoogleAccount (CoreDataGeneratedPrimitiveAccessors)

@end
