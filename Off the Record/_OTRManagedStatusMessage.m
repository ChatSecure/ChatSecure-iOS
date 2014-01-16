// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedStatusMessage.m instead.

#import "_OTRManagedStatusMessage.h"

const struct OTRManagedStatusMessageAttributes OTRManagedStatusMessageAttributes = {
	.status = @"status",
};

const struct OTRManagedStatusMessageRelationships OTRManagedStatusMessageRelationships = {
};

const struct OTRManagedStatusMessageFetchedProperties OTRManagedStatusMessageFetchedProperties = {
};

@implementation OTRManagedStatusMessageID
@end

@implementation _OTRManagedStatusMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedStatusMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedStatusMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedStatusMessage" inManagedObjectContext:moc_];
}

- (OTRManagedStatusMessageID*)objectID {
	return (OTRManagedStatusMessageID*)[super objectID];
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










@end
