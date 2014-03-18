// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedEncryptionMessage.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedMessage.h"

extern const struct OTRManagedEncryptionMessageAttributes {
	__unsafe_unretained NSString *status;
} OTRManagedEncryptionMessageAttributes;

extern const struct OTRManagedEncryptionMessageRelationships {
} OTRManagedEncryptionMessageRelationships;

extern const struct OTRManagedEncryptionMessageFetchedProperties {
} OTRManagedEncryptionMessageFetchedProperties;




@interface OTRManagedEncryptionMessageID : NSManagedObjectID {}
@end

@interface _OTRManagedEncryptionMessage : OTRManagedMessage {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedEncryptionMessageID*)objectID;





@property (nonatomic, strong) NSNumber* status;



@property int16_t statusValue;
- (int16_t)statusValue;
- (void)setStatusValue:(int16_t)value_;

//- (BOOL)validateStatus:(id*)value_ error:(NSError**)error_;






@end

@interface _OTRManagedEncryptionMessage (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedEncryptionMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveStatus;
- (void)setPrimitiveStatus:(NSNumber*)value;

- (int16_t)primitiveStatusValue;
- (void)setPrimitiveStatusValue:(int16_t)value_;




@end
