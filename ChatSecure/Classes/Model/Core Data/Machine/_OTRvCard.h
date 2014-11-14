// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRvCard.h instead.

#import <CoreData/CoreData.h>


extern const struct OTRvCardAttributes {
	__unsafe_unretained NSString *jidString;
	__unsafe_unretained NSString *lastUpdated;
	__unsafe_unretained NSString *photoHash;
	__unsafe_unretained NSString *waitingForFetch;
} OTRvCardAttributes;

extern const struct OTRvCardRelationships {
	__unsafe_unretained NSString *vCardAvatarRelationship;
	__unsafe_unretained NSString *vCardTempRelationship;
} OTRvCardRelationships;

extern const struct OTRvCardFetchedProperties {
} OTRvCardFetchedProperties;

@class OTRvCardAvatar;
@class OTRvCardTemp;






@interface OTRvCardID : NSManagedObjectID {}
@end

@interface _OTRvCard : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRvCardID*)objectID;





@property (nonatomic, strong) NSString* jidString;



//- (BOOL)validateJidString:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* lastUpdated;



//- (BOOL)validateLastUpdated:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* photoHash;



//- (BOOL)validatePhotoHash:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* waitingForFetch;



@property BOOL waitingForFetchValue;
- (BOOL)waitingForFetchValue;
- (void)setWaitingForFetchValue:(BOOL)value_;

//- (BOOL)validateWaitingForFetch:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) OTRvCardAvatar *vCardAvatarRelationship;

//- (BOOL)validateVCardAvatarRelationship:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) OTRvCardTemp *vCardTempRelationship;

//- (BOOL)validateVCardTempRelationship:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRvCard (CoreDataGeneratedAccessors)

@end

@interface _OTRvCard (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveJidString;
- (void)setPrimitiveJidString:(NSString*)value;




- (NSDate*)primitiveLastUpdated;
- (void)setPrimitiveLastUpdated:(NSDate*)value;




- (NSString*)primitivePhotoHash;
- (void)setPrimitivePhotoHash:(NSString*)value;




- (NSNumber*)primitiveWaitingForFetch;
- (void)setPrimitiveWaitingForFetch:(NSNumber*)value;

- (BOOL)primitiveWaitingForFetchValue;
- (void)setPrimitiveWaitingForFetchValue:(BOOL)value_;





- (OTRvCardAvatar*)primitiveVCardAvatarRelationship;
- (void)setPrimitiveVCardAvatarRelationship:(OTRvCardAvatar*)value;



- (OTRvCardTemp*)primitiveVCardTempRelationship;
- (void)setPrimitiveVCardTempRelationship:(OTRvCardTemp*)value;


@end
