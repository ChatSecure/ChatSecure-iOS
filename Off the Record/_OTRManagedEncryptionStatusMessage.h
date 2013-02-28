// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedEncryptionStatusMessage.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedMessageAndStatus.h"

extern const struct OTRManagedEncryptionStatusMessageAttributes {
	__unsafe_unretained NSString *status;
} OTRManagedEncryptionStatusMessageAttributes;

extern const struct OTRManagedEncryptionStatusMessageRelationships {
	__unsafe_unretained NSString *encryptionstatusbuddy;
} OTRManagedEncryptionStatusMessageRelationships;

extern const struct OTRManagedEncryptionStatusMessageFetchedProperties {
} OTRManagedEncryptionStatusMessageFetchedProperties;

@class OTRManagedBuddy;



@interface OTRManagedEncryptionStatusMessageID : NSManagedObjectID {}
@end

@interface _OTRManagedEncryptionStatusMessage : OTRManagedMessageAndStatus {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedEncryptionStatusMessageID*)objectID;





@property (nonatomic, strong) NSNumber* status;



@property int16_t statusValue;
- (int16_t)statusValue;
- (void)setStatusValue:(int16_t)value_;

//- (BOOL)validateStatus:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) OTRManagedBuddy *encryptionstatusbuddy;

//- (BOOL)validateEncryptionstatusbuddy:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRManagedEncryptionStatusMessage (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedEncryptionStatusMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveStatus;
- (void)setPrimitiveStatus:(NSNumber*)value;

- (int16_t)primitiveStatusValue;
- (void)setPrimitiveStatusValue:(int16_t)value_;





- (OTRManagedBuddy*)primitiveEncryptionstatusbuddy;
- (void)setPrimitiveEncryptionstatusbuddy:(OTRManagedBuddy*)value;


@end
