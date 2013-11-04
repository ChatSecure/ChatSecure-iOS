// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRvCardAvatar.m instead.

#import "_OTRvCardAvatar.h"

const struct OTRvCardAvatarAttributes OTRvCardAvatarAttributes = {
	.photoData = @"photoData",
};

const struct OTRvCardAvatarRelationships OTRvCardAvatarRelationships = {
	.vCard = @"vCard",
};

const struct OTRvCardAvatarFetchedProperties OTRvCardAvatarFetchedProperties = {
};

@implementation OTRvCardAvatarID
@end

@implementation _OTRvCardAvatar

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRvCardAvatar" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRvCardAvatar";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRvCardAvatar" inManagedObjectContext:moc_];
}

- (OTRvCardAvatarID*)objectID {
	return (OTRvCardAvatarID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic photoData;






@dynamic vCard;

	






@end
