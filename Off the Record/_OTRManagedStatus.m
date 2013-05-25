// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedStatus.m instead.

#import "_OTRManagedStatus.h"

const struct OTRManagedStatusAttributes OTRManagedStatusAttributes = {
	.status = @"status",
};

const struct OTRManagedStatusRelationships OTRManagedStatusRelationships = {
	.statusbuddy = @"statusbuddy",
};

const struct OTRManagedStatusFetchedProperties OTRManagedStatusFetchedProperties = {
};

@implementation OTRManagedStatusID
@end

@implementation _OTRManagedStatus

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedStatus" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedStatus";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedStatus" inManagedObjectContext:moc_];
}

- (OTRManagedStatusID*)objectID {
	return (OTRManagedStatusID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"statusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"status"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic status;



- (int16_t)statusValue {
	NSNumber *result = [self status];
	return [result shortValue];
}

- (void)setStatusValue:(int16_t)value_ {
	[self setStatus:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveStatusValue {
	NSNumber *result = [self primitiveStatus];
	return [result shortValue];
}

- (void)setPrimitiveStatusValue:(int16_t)value_ {
	[self setPrimitiveStatus:[NSNumber numberWithShort:value_]];
}





@dynamic statusbuddy;

	






@end
