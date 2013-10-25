// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRvCardAvatar.h instead.

#import <CoreData/CoreData.h>


extern const struct OTRvCardAvatarAttributes {
	__unsafe_unretained NSString *photoData;
} OTRvCardAvatarAttributes;

extern const struct OTRvCardAvatarRelationships {
	__unsafe_unretained NSString *vCard;
} OTRvCardAvatarRelationships;

extern const struct OTRvCardAvatarFetchedProperties {
} OTRvCardAvatarFetchedProperties;

@class OTRvCard;



@interface OTRvCardAvatarID : NSManagedObjectID {}
@end

@interface _OTRvCardAvatar : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRvCardAvatarID*)objectID;





@property (nonatomic, strong) NSData* photoData;



//- (BOOL)validatePhotoData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) OTRvCard *vCard;

//- (BOOL)validateVCard:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRvCardAvatar (CoreDataGeneratedAccessors)

@end

@interface _OTRvCardAvatar (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitivePhotoData;
- (void)setPrimitivePhotoData:(NSData*)value;





- (OTRvCard*)primitiveVCard;
- (void)setPrimitiveVCard:(OTRvCard*)value;


@end
