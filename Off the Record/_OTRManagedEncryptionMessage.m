// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedEncryptionMessage.m instead.

#import "_OTRManagedEncryptionMessage.h"

const struct OTRManagedEncryptionMessageAttributes OTRManagedEncryptionMessageAttributes = {
	.status = @"status",
};

const struct OTRManagedEncryptionMessageRelationships OTRManagedEncryptionMessageRelationships = {
};

const struct OTRManagedEncryptionMessageFetchedProperties OTRManagedEncryptionMessageFetchedProperties = {
};

@implementation OTRManagedEncryptionMessageID
@end

@implementation _OTRManagedEncryptionMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedEncryptionMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedEncryptionMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedEncryptionMessage" inManagedObjectContext:moc_];
}

- (OTRManagedEncryptionMessageID*)objectID {
	return (OTRManagedEncryptionMessageID*)[super objectID];
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
