// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedEncryptionStatusMessage.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedMessageAndStatus.h"

extern const struct OTRManagedEncryptionStatusMessageAttributes {
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





@property (nonatomic, strong) OTRManagedBuddy *encryptionstatusbuddy;

//- (BOOL)validateEncryptionstatusbuddy:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRManagedEncryptionStatusMessage (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedEncryptionStatusMessage (CoreDataGeneratedPrimitiveAccessors)



- (OTRManagedBuddy*)primitiveEncryptionstatusbuddy;
- (void)setPrimitiveEncryptionstatusbuddy:(OTRManagedBuddy*)value;


@end
