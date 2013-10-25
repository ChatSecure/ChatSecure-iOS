// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRvCardTemp.h instead.

#import <CoreData/CoreData.h>


extern const struct OTRvCardTempAttributes {
	__unsafe_unretained NSString *vCardTemp;
} OTRvCardTempAttributes;

extern const struct OTRvCardTempRelationships {
	__unsafe_unretained NSString *vCard;
} OTRvCardTempRelationships;

extern const struct OTRvCardTempFetchedProperties {
} OTRvCardTempFetchedProperties;

@class OTRvCard;

@class NSObject;

@interface OTRvCardTempID : NSManagedObjectID {}
@end

@interface _OTRvCardTemp : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRvCardTempID*)objectID;





@property (nonatomic, strong) id vCardTemp;



//- (BOOL)validateVCardTemp:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) OTRvCard *vCard;

//- (BOOL)validateVCard:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRvCardTemp (CoreDataGeneratedAccessors)

@end

@interface _OTRvCardTemp (CoreDataGeneratedPrimitiveAccessors)


- (id)primitiveVCardTemp;
- (void)setPrimitiveVCardTemp:(id)value;





- (OTRvCard*)primitiveVCard;
- (void)setPrimitiveVCard:(OTRvCard*)value;


@end
