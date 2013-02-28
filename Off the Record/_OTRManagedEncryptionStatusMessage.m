// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedEncryptionStatusMessage.m instead.

#import "_OTRManagedEncryptionStatusMessage.h"

const struct OTRManagedEncryptionStatusMessageAttributes OTRManagedEncryptionStatusMessageAttributes = {
	.status = @"status",
};

const struct OTRManagedEncryptionStatusMessageRelationships OTRManagedEncryptionStatusMessageRelationships = {
	.encryptionstatusbuddy = @"encryptionstatusbuddy",
};

const struct OTRManagedEncryptionStatusMessageFetchedProperties OTRManagedEncryptionStatusMessageFetchedProperties = {
};

@implementation OTRManagedEncryptionStatusMessageID
@end

@implementation _OTRManagedEncryptionStatusMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedEncryptionStatusMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedEncryptionStatusMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedEncryptionStatusMessage" inManagedObjectContext:moc_];
}

- (OTRManagedEncryptionStatusMessageID*)objectID {
	return (OTRManagedEncryptionStatusMessageID*)[super objectID];
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





@dynamic encryptionstatusbuddy;

	






@end
