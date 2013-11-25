// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedAccount.m instead.

#import "_OTRManagedAccount.h"

const struct OTRManagedAccountAttributes OTRManagedAccountAttributes = {
	.protocol = @"protocol",
	.rememberPassword = @"rememberPassword",
	.uniqueIdentifier = @"uniqueIdentifier",
	.username = @"username",
};

const struct OTRManagedAccountRelationships OTRManagedAccountRelationships = {
	.buddies = @"buddies",
};

const struct OTRManagedAccountFetchedProperties OTRManagedAccountFetchedProperties = {
};

@implementation OTRManagedAccountID
@end

@implementation _OTRManagedAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedAccount" inManagedObjectContext:moc_];
}

- (OTRManagedAccountID*)objectID {
	return (OTRManagedAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"rememberPasswordValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"rememberPassword"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic protocol;






@dynamic rememberPassword;



- (BOOL)rememberPasswordValue {
	NSNumber *result = [self rememberPassword];
	return [result boolValue];
}

- (void)setRememberPasswordValue:(BOOL)value_ {
	[self setRememberPassword:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveRememberPasswordValue {
	NSNumber *result = [self primitiveRememberPassword];
	return [result boolValue];
}

- (void)setPrimitiveRememberPasswordValue:(BOOL)value_ {
	[self setPrimitiveRememberPassword:[NSNumber numberWithBool:value_]];
}





@dynamic uniqueIdentifier;






@dynamic username;






@dynamic buddies;

	
- (NSMutableSet*)buddiesSet {
	[self willAccessValueForKey:@"buddies"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"buddies"];
  
	[self didAccessValueForKey:@"buddies"];
	return result;
}
	






@end
