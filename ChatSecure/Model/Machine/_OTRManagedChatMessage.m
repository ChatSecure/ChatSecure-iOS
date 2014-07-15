// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedChatMessage.m instead.

#import "_OTRManagedChatMessage.h"

const struct OTRManagedChatMessageAttributes OTRManagedChatMessageAttributes = {
	.isDelivered = @"isDelivered",
	.isRead = @"isRead",
	.uniqueID = @"uniqueID",
};

const struct OTRManagedChatMessageRelationships OTRManagedChatMessageRelationships = {
	.chatBuddy = @"chatBuddy",
};

const struct OTRManagedChatMessageFetchedProperties OTRManagedChatMessageFetchedProperties = {
};

@implementation OTRManagedChatMessageID
@end

@implementation _OTRManagedChatMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedChatMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedChatMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedChatMessage" inManagedObjectContext:moc_];
}

- (OTRManagedChatMessageID*)objectID {
	return (OTRManagedChatMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"isDeliveredValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isDelivered"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"isReadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isRead"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic isDelivered;



- (BOOL)isDeliveredValue {
	NSNumber *result = [self isDelivered];
	return [result boolValue];
}

- (void)setIsDeliveredValue:(BOOL)value_ {
	[self setIsDelivered:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsDeliveredValue {
	NSNumber *result = [self primitiveIsDelivered];
	return [result boolValue];
}

- (void)setPrimitiveIsDeliveredValue:(BOOL)value_ {
	[self setPrimitiveIsDelivered:[NSNumber numberWithBool:value_]];
}





@dynamic isRead;



- (BOOL)isReadValue {
	NSNumber *result = [self isRead];
	return [result boolValue];
}

- (void)setIsReadValue:(BOOL)value_ {
	[self setIsRead:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsReadValue {
	NSNumber *result = [self primitiveIsRead];
	return [result boolValue];
}

- (void)setPrimitiveIsReadValue:(BOOL)value_ {
	[self setPrimitiveIsRead:[NSNumber numberWithBool:value_]];
}





@dynamic uniqueID;






@dynamic chatBuddy;

	






@end
