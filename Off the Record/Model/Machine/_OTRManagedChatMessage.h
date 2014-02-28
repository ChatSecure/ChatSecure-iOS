// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedChatMessage.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedMessage.h"

extern const struct OTRManagedChatMessageAttributes {
	__unsafe_unretained NSString *isDelivered;
	__unsafe_unretained NSString *isRead;
	__unsafe_unretained NSString *uniqueID;
} OTRManagedChatMessageAttributes;

extern const struct OTRManagedChatMessageRelationships {
	__unsafe_unretained NSString *chatBuddy;
} OTRManagedChatMessageRelationships;

extern const struct OTRManagedChatMessageFetchedProperties {
} OTRManagedChatMessageFetchedProperties;

@class OTRManagedBuddy;





@interface OTRManagedChatMessageID : NSManagedObjectID {}
@end

@interface _OTRManagedChatMessage : OTRManagedMessage {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedChatMessageID*)objectID;





@property (nonatomic, strong) NSNumber* isDelivered;



@property BOOL isDeliveredValue;
- (BOOL)isDeliveredValue;
- (void)setIsDeliveredValue:(BOOL)value_;

//- (BOOL)validateIsDelivered:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* isRead;



@property BOOL isReadValue;
- (BOOL)isReadValue;
- (void)setIsReadValue:(BOOL)value_;

//- (BOOL)validateIsRead:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* uniqueID;



//- (BOOL)validateUniqueID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) OTRManagedBuddy *chatBuddy;

//- (BOOL)validateChatBuddy:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRManagedChatMessage (CoreDataGeneratedAccessors)

@end

@interface _OTRManagedChatMessage (CoreDataGeneratedPrimitiveAccessors)


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





- (OTRManagedBuddy*)primitiveChatBuddy;
- (void)setPrimitiveChatBuddy:(OTRManagedBuddy*)value;


@end
