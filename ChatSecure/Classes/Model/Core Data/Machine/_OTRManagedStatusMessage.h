// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedStatusMessage.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedMessage.h"

extern const struct OTRManagedStatusMessageAttributes {
	__unsafe_unretained NSString *status;
} OTRManagedStatusMessageAttributes;

extern const struct OTRManagedStatusMessageRelationships {
} OTRManagedStatusMessageRelationships;

extern const struct OTRManagedStatusMessageFetchedProperties {
} OTRManagedStatusMessageFetchedProperties;




@interface OTRManagedStatusMessageID : NSManagedObjectID {}
@end

@interface _OTRManagedStatusMessage : OTRManagedMessage {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedStatusMessageID*)objectID;





@property (nonatomic, strong) NSNumber* status;



@property int16_t statusValue;
- (int16_t)statusValue;
- (void)setStatusValue:(int16_t)value_;

//- (BOOL)validateStatus:(id*)value_ error:(NSError**)error_;






@end

@interface _OTRManagedStatusMessage (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedStatusMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveStatus;
- (void)setPrimitiveStatus:(NSNumber*)value;

- (int16_t)primitiveStatusValue;
- (void)setPrimitiveStatusValue:(int16_t)value_;




@end
