// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedBuddy.m instead.

#import "_OTRManagedBuddy.h"

const struct OTRManagedBuddyAttributes OTRManagedBuddyAttributes = {
	.accountName = @"accountName",
	.chatState = @"chatState",
	.composingMessageString = @"composingMessageString",
	.currentStatus = @"currentStatus",
	.displayName = @"displayName",
	.lastMessageDate = @"lastMessageDate",
	.lastMessageDisconnected = @"lastMessageDisconnected",
	.lastSentChatState = @"lastSentChatState",
	.photo = @"photo",
};

const struct OTRManagedBuddyRelationships OTRManagedBuddyRelationships = {
	.account = @"account",
	.encryptionStatusMessages = @"encryptionStatusMessages",
	.groups = @"groups",
	.messages = @"messages",
	.messagesandstatuses = @"messagesandstatuses",
	.statuses = @"statuses",
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
	if ([key isEqualToString:@"currentStatusValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"currentStatus"];
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






@dynamic currentStatus;



- (int16_t)currentStatusValue {
	NSNumber *result = [self currentStatus];
	return [result shortValue];
}

- (void)setCurrentStatusValue:(int16_t)value_ {
	[self setCurrentStatus:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveCurrentStatusValue {
	NSNumber *result = [self primitiveCurrentStatus];
	return [result shortValue];
}

- (void)setPrimitiveCurrentStatusValue:(int16_t)value_ {
	[self setPrimitiveCurrentStatus:[NSNumber numberWithShort:value_]];
}





@dynamic displayName;






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





@dynamic photo;






@dynamic account;

	

@dynamic encryptionStatusMessages;

	
- (NSMutableSet*)encryptionStatusMessagesSet {
	[self willAccessValueForKey:@"encryptionStatusMessages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"encryptionStatusMessages"];
  
	[self didAccessValueForKey:@"encryptionStatusMessages"];
	return result;
}
	

@dynamic groups;

	
- (NSMutableSet*)groupsSet {
	[self willAccessValueForKey:@"groups"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"groups"];
  
	[self didAccessValueForKey:@"groups"];
	return result;
}
	

@dynamic messages;

	
- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];
  
	[self didAccessValueForKey:@"messages"];
	return result;
}
	

@dynamic messagesandstatuses;

	
- (NSMutableSet*)messagesandstatusesSet {
	[self willAccessValueForKey:@"messagesandstatuses"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messagesandstatuses"];
  
	[self didAccessValueForKey:@"messagesandstatuses"];
	return result;
}
	

@dynamic statuses;

	
- (NSMutableSet*)statusesSet {
	[self willAccessValueForKey:@"statuses"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"statuses"];
  
	[self didAccessValueForKey:@"statuses"];
	return result;
}
	






@end
