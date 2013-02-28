// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedGroup.h instead.

#import <CoreData/CoreData.h>


extern const struct OTRManagedGroupAttributes {
	__unsafe_unretained NSString *name;
} OTRManagedGroupAttributes;

extern const struct OTRManagedGroupRelationships {
	__unsafe_unretained NSString *buddies;
} OTRManagedGroupRelationships;

extern const struct OTRManagedGroupFetchedProperties {
} OTRManagedGroupFetchedProperties;

@class OTRManagedBuddy;



@interface OTRManagedGroupID : NSManagedObjectID {}
@end

@interface _OTRManagedGroup : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedGroupID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *buddies;

- (NSMutableSet*)buddiesSet;





@end

@interface _OTRManagedGroup (CoreDataGeneratedAccessors)

- (void)addBuddies:(NSSet*)value_;
- (void)removeBuddies:(NSSet*)value_;
- (void)addBuddiesObject:(OTRManagedBuddy*)value_;
- (void)removeBuddiesObject:(OTRManagedBuddy*)value_;

@end

@interface _OTRManagedGroup (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableSet*)primitiveBuddies;
- (void)setPrimitiveBuddies:(NSMutableSet*)value;


@end
