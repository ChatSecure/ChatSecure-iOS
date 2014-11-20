// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedMessage.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedMessageAndStatus.h"

extern const struct OTRManagedMessageAttributes {
	__unsafe_unretained NSString *isDelivered;
	__unsafe_unretained NSString *isRead;
	__unsafe_unretained NSString *uniqueID;
} OTRManagedMessageAttributes;

extern const struct OTRManagedMessageRelationships {
	__unsafe_unretained NSString *messagebuddy;
} OTRManagedMessageRelationships;

@class OTRManagedBuddy;

@interface OTRManagedMessageID : OTRManagedMessageAndStatusID {}
@end

@interface _OTRManagedMessage : OTRManagedMessageAndStatus {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) OTRManagedMessageID* objectID;

@property (nonatomic, strong) NSNumber* isDelivered;

@property (atomic) BOOL isDeliveredValue;
- (BOOL)isDeliveredValue;
- (void)setIsDeliveredValue:(BOOL)value_;

//- (BOOL)validateIsDelivered:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* isRead;

@property (atomic) BOOL isReadValue;
- (BOOL)isReadValue;
- (void)setIsReadValue:(BOOL)value_;

//- (BOOL)validateIsRead:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* uniqueID;

//- (BOOL)validateUniqueID:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) OTRManagedBuddy *messagebuddy;

//- (BOOL)validateMessagebuddy:(id*)value_ error:(NSError**)error_;

@end

@interface _OTRManagedMessage (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveIsDelivered;
- (void)setPrimitiveIsDelivered:(NSNumber*)value;

- (BOOL)primitiveIsDeliveredValue;
- (void)setPrimitiveIsDeliveredValue:(BOOL)value_;

- (NSNumber*)primitiveIsRead;
- (void)setPrimitiveIsRead:(NSNumber*)value;

- (BOOL)primitiveIsReadValue;
- (void)setPrimitiveIsReadValue:(BOOL)value_;

- (NSString*)primitiveUniqueID;
- (void)setPrimitiveUniqueID:(NSString*)value;

- (OTRManagedBuddy*)primitiveMessagebuddy;
- (void)setPrimitiveMessagebuddy:(OTRManagedBuddy*)value;

@end
