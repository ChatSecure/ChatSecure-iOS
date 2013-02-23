// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedBuddy.m instead.

#import "_OTRManagedBuddy.h"

const struct OTRManagedBuddyAttributes OTRManagedBuddyAttributes = {
	.accountName = @"accountName",
	.chatState = @"chatState",
	.composingMessageString = @"composingMessageString",
	.displayName = @"displayName",
	.encryptionStatus = @"encryptionStatus",
	.groupName = @"groupName",
	.lastMessageDate = @"lastMessageDate",
	.lastMessageDisconnected = @"lastMessageDisconnected",
	.lastSentChatState = @"lastSentChatState",
	.status = @"status",
	.statusMessage = @"statusMessage",
};

const struct OTRManagedBuddyRelationships OTRManagedBuddyRelationships = {
	.account = @"account",
	.messages = @"messages",
};

const struct OTRManagedBuddyFetchedProperties OTRManagedBuddyFetchedProperties = {
};

@implementation OTRManagedBuddyID
@end

@implementation _OTRManagedBuddy

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedBuddy" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedBuddy";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedBuddy" inManagedObjectContext:moc_];
}

- (OTRManagedBuddyID*)objectID {
	return (OTRManagedBuddyID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"chatStateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"chatState"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"encryptionStatusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"encryptionStatus"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"lastMessageDisconnectedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lastMessageDisconnected"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"lastSentChatStateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"lastSentChatState"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"statusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"status"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic accountName;






@dynamic chatState;



- (int16_t)chatStateValue {
	NSNumber *result = [self chatState];
	return [result shortValue];
}

- (void)setChatStateValue:(int16_t)value_ {
	[self setChatState:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveChatStateValue {
	NSNumber *result = [self primitiveChatState];
	return [result shortValue];
}

- (void)setPrimitiveChatStateValue:(int16_t)value_ {
	[self setPrimitiveChatState:[NSNumber numberWithShort:value_]];
}





@dynamic composingMessageString;






@dynamic displayName;






@dynamic encryptionStatus;



- (int16_t)encryptionStatusValue {
	NSNumber *result = [self encryptionStatus];
	return [result shortValue];
}

- (void)setEncryptionStatusValue:(int16_t)value_ {
	[self setEncryptionStatus:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveEncryptionStatusValue {
	NSNumber *result = [self primitiveEncryptionStatus];
	return [result shortValue];
}

- (void)setPrimitiveEncryptionStatusValue:(int16_t)value_ {
	[self setPrimitiveEncryptionStatus:[NSNumber numberWithShort:value_]];
}





@dynamic groupName;






@dynamic lastMessageDate;






@dynamic lastMessageDisconnected;



- (BOOL)lastMessageDisconnectedValue {
	NSNumber *result = [self lastMessageDisconnected];
	return [result boolValue];
}

- (void)setLastMessageDisconnectedValue:(BOOL)value_ {
	[self setLastMessageDisconnected:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveLastMessageDisconnectedValue {
	NSNumber *result = [self primitiveLastMessageDisconnected];
	return [result boolValue];
}

- (void)setPrimitiveLastMessageDisconnectedValue:(BOOL)value_ {
	[self setPrimitiveLastMessageDisconnected:[NSNumber numberWithBool:value_]];
}





@dynamic lastSentChatState;



- (int16_t)lastSentChatStateValue {
	NSNumber *result = [self lastSentChatState];
	return [result shortValue];
}

- (void)setLastSentChatStateValue:(int16_t)value_ {
	[self setLastSentChatState:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveLastSentChatStateValue {
	NSNumber *result = [self primitiveLastSentChatState];
	return [result shortValue];
}

- (void)setPrimitiveLastSentChatStateValue:(int16_t)value_ {
	[self setPrimitiveLastSentChatState:[NSNumber numberWithShort:value_]];
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





@dynamic statusMessage;






@dynamic account;

	

@dynamic messages;

	
- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];
  
	[self didAccessValueForKey:@"messages"];
	return result;
}
	






@end
