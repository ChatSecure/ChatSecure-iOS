// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRvCard.m instead.

#import "_OTRvCard.h"

const struct OTRvCardAttributes OTRvCardAttributes = {
	.jidString = @"jidString",
	.lastUpdated = @"lastUpdated",
	.photoHash = @"photoHash",
	.waitingForFetch = @"waitingForFetch",
};

const struct OTRvCardRelationships OTRvCardRelationships = {
	.vCardAvatarRelationship = @"vCardAvatarRelationship",
	.vCardTempRelationship = @"vCardTempRelationship",
};

const struct OTRvCardFetchedProperties OTRvCardFetchedProperties = {
};

@implementation OTRvCardID
@end

@implementation _OTRvCard

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRvCard" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRvCard";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRvCard" inManagedObjectContext:moc_];
}

- (OTRvCardID*)objectID {
	return (OTRvCardID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"waitingForFetchValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"waitingForFetch"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic jidString;






@dynamic lastUpdated;






@dynamic photoHash;






@dynamic waitingForFetch;



- (BOOL)waitingForFetchValue {
	NSNumber *result = [self waitingForFetch];
	return [result boolValue];
}

- (void)setWaitingForFetchValue:(BOOL)value_ {
	[self setWaitingForFetch:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveWaitingForFetchValue {
	NSNumber *result = [self primitiveWaitingForFetch];
	return [result boolValue];
}

- (void)setPrimitiveWaitingForFetchValue:(BOOL)value_ {
	[self setPrimitiveWaitingForFetch:[NSNumber numberWithBool:value_]];
}





@dynamic vCardAvatarRelationship;

	

@dynamic vCardTempRelationship;

	






@end
