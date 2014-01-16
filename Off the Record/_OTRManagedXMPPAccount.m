// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedXMPPAccount.m instead.

#import "_OTRManagedXMPPAccount.h"

const struct OTRManagedXMPPAccountAttributes OTRManagedXMPPAccountAttributes = {
	.domain = @"domain",
	.port = @"port",
};

const struct OTRManagedXMPPAccountRelationships OTRManagedXMPPAccountRelationships = {
	.subscriptionRequests = @"subscriptionRequests",
};

const struct OTRManagedXMPPAccountFetchedProperties OTRManagedXMPPAccountFetchedProperties = {
};

@implementation OTRManagedXMPPAccountID
@end

@implementation _OTRManagedXMPPAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedXMPPAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedXMPPAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedXMPPAccount" inManagedObjectContext:moc_];
}

- (OTRManagedXMPPAccountID*)objectID {
	return (OTRManagedXMPPAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"portValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"port"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic domain;






@dynamic port;



- (int16_t)portValue {
	NSNumber *result = [self port];
	return [result shortValue];
}

- (void)setPortValue:(int16_t)value_ {
	[self setPort:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitivePortValue {
	NSNumber *result = [self primitivePort];
	return [result shortValue];
}

- (void)setPrimitivePortValue:(int16_t)value_ {
	[self setPrimitivePort:[NSNumber numberWithShort:value_]];
}





@dynamic subscriptionRequests;

	
- (NSMutableSet*)subscriptionRequestsSet {
	[self willAccessValueForKey:@"subscriptionRequests"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"subscriptionRequests"];
  
	[self didAccessValueForKey:@"subscriptionRequests"];
	return result;
}
	






@end
