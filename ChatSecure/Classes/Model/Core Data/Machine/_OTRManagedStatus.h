// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedStatus.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedMessageAndStatus.h"

extern const struct OTRManagedStatusAttributes {
	__unsafe_unretained NSString *status;
} OTRManagedStatusAttributes;

extern const struct OTRManagedStatusRelationships {
	__unsafe_unretained NSString *statusbuddy;
} OTRManagedStatusRelationships;

@class OTRManagedBuddy;

@interface OTRManagedStatusID : OTRManagedMessageAndStatusID {}
@end

@interface _OTRManagedStatus : OTRManagedMessageAndStatus {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) OTRManagedStatusID* objectID;

@property (nonatomic, strong) NSNumber* status;

@property (atomic) int16_t statusValue;
- (int16_t)statusValue;
- (void)setStatusValue:(int16_t)value_;

//- (BOOL)validateStatus:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) OTRManagedBuddy *statusbuddy;

//- (BOOL)validateStatusbuddy:(id*)value_ error:(NSError**)error_;

@end

@interface _OTRManagedStatus (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveStatus;
- (void)setPrimitiveStatus:(NSNumber*)value;

- (int16_t)primitiveStatusValue;
- (void)setPrimitiveStatusValue:(int16_t)value_;

- (OTRManagedBuddy*)primitiveStatusbuddy;
- (void)setPrimitiveStatusbuddy:(OTRManagedBuddy*)value;

@end
