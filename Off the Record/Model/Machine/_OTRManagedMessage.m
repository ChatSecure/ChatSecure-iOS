// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedMessage.m instead.

#import "_OTRManagedMessage.h"

const struct OTRManagedMessageAttributes OTRManagedMessageAttributes = {
	.date = @"date",
	.isEncrypted = @"isEncrypted",
	.isIncoming = @"isIncoming",
	.message = @"message",
};

const struct OTRManagedMessageRelationships OTRManagedMessageRelationships = {
	.buddy = @"buddy",
};

const struct OTRManagedMessageFetchedProperties OTRManagedMessageFetchedProperties = {
};

@implementation OTRManagedMessageID
@end

@implementation _OTRManagedMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedMessage" inManagedObjectContext:moc_];
}

- (OTRManagedMessageID*)objectID {
	return (OTRManagedMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"isEncryptedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isEncrypted"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"isIncomingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isIncoming"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic date;






@dynamic isEncrypted;



- (BOOL)isEncryptedValue {
	NSNumber *result = [self isEncrypted];
	return [result boolValue];
}

- (void)setIsEncryptedValue:(BOOL)value_ {
	[self setIsEncrypted:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsEncryptedValue {
	NSNumber *result = [self primitiveIsEncrypted];
	return [result boolValue];
}

- (void)setPrimitiveIsEncryptedValue:(BOOL)value_ {
	[self setPrimitiveIsEncrypted:[NSNumber numberWithBool:value_]];
}





@dynamic isIncoming;



- (BOOL)isIncomingValue {
	NSNumber *result = [self isIncoming];
	return [result boolValue];
}

- (void)setIsIncomingValue:(BOOL)value_ {
	[self setIsIncoming:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsIncomingValue {
	NSNumber *result = [self primitiveIsIncoming];
	return [result boolValue];
}

- (void)setPrimitiveIsIncomingValue:(BOOL)value_ {
	[self setPrimitiveIsIncoming:[NSNumber numberWithBool:value_]];
}





@dynamic message;






@dynamic buddy;

	






@end
