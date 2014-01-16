// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedMessage.h instead.

#import <CoreData/CoreData.h>


extern const struct OTRManagedMessageAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *isEncrypted;
	__unsafe_unretained NSString *isIncoming;
	__unsafe_unretained NSString *message;
} OTRManagedMessageAttributes;

extern const struct OTRManagedMessageRelationships {
	__unsafe_unretained NSString *buddy;
} OTRManagedMessageRelationships;

extern const struct OTRManagedMessageFetchedProperties {
} OTRManagedMessageFetchedProperties;

@class OTRManagedBuddy;






@interface OTRManagedMessageID : NSManagedObjectID {}
@end

@interface _OTRManagedMessage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedMessageID*)objectID;





@property (nonatomic, strong) NSDate* date;



//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* isEncrypted;



@property BOOL isEncryptedValue;
- (BOOL)isEncryptedValue;
- (void)setIsEncryptedValue:(BOOL)value_;

//- (BOOL)validateIsEncrypted:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* isIncoming;



@property BOOL isIncomingValue;
- (BOOL)isIncomingValue;
- (void)setIsIncomingValue:(BOOL)value_;

//- (BOOL)validateIsIncoming:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* message;



//- (BOOL)validateMessage:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) OTRManagedBuddy *buddy;

//- (BOOL)validateBuddy:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRManagedMessage (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;




- (NSNumber*)primitiveIsEncrypted;
- (void)setPrimitiveIsEncrypted:(NSNumber*)value;

- (BOOL)primitiveIsEncryptedValue;
- (void)setPrimitiveIsEncryptedValue:(BOOL)value_;




- (NSNumber*)primitiveIsIncoming;
- (void)setPrimitiveIsIncoming:(NSNumber*)value;

- (BOOL)primitiveIsIncomingValue;
- (void)setPrimitiveIsIncomingValue:(BOOL)value_;




- (NSString*)primitiveMessage;
- (void)setPrimitiveMessage:(NSString*)value;





- (OTRManagedBuddy*)primitiveBuddy;
- (void)setPrimitiveBuddy:(OTRManagedBuddy*)value;


@end
