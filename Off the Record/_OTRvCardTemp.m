// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRvCardTemp.m instead.

#import "_OTRvCardTemp.h"

const struct OTRvCardTempAttributes OTRvCardTempAttributes = {
	.vCardTemp = @"vCardTemp",
};

const struct OTRvCardTempRelationships OTRvCardTempRelationships = {
	.vCard = @"vCard",
};

const struct OTRvCardTempFetchedProperties OTRvCardTempFetchedProperties = {
};

@implementation OTRvCardTempID
@end

@implementation _OTRvCardTemp

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRvCardTemp" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRvCardTemp";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRvCardTemp" inManagedObjectContext:moc_];
}

- (OTRvCardTempID*)objectID {
	return (OTRvCardTempID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic vCardTemp;






@dynamic vCard;

	






@end
