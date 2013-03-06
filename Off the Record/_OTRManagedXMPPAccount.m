// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedXMPPAccount.m instead.

#import "_OTRManagedXMPPAccount.h"

const struct OTRManagedXMPPAccountAttributes OTRManagedXMPPAccountAttributes = {
	.allowPlainTextAuthentication = @"allowPlainTextAuthentication",
	.allowSSLHostNameMismatch = @"allowSSLHostNameMismatch",
	.allowSelfSignedSSL = @"allowSelfSignedSSL",
	.domain = @"domain",
	.port = @"port",
	.requireTLS = @"requireTLS",
	.sendDeliveryReceipts = @"sendDeliveryReceipts",
	.sendTypingNotifications = @"sendTypingNotifications",
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
	
	if ([key isEqualToString:@"allowPlainTextAuthenticationValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"allowPlainTextAuthentication"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"allowSSLHostNameMismatchValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"allowSSLHostNameMismatch"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"allowSelfSignedSSLValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"allowSelfSignedSSL"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"portValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"port"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"requireTLSValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"requireTLS"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"sendDeliveryReceiptsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sendDeliveryReceipts"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"sendTypingNotificationsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sendTypingNotifications"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic allowPlainTextAuthentication;



- (BOOL)allowPlainTextAuthenticationValue {
	NSNumber *result = [self allowPlainTextAuthentication];
	return [result boolValue];
}

- (void)setAllowPlainTextAuthenticationValue:(BOOL)value_ {
	[self setAllowPlainTextAuthentication:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveAllowPlainTextAuthenticationValue {
	NSNumber *result = [self primitiveAllowPlainTextAuthentication];
	return [result boolValue];
}

- (void)setPrimitiveAllowPlainTextAuthenticationValue:(BOOL)value_ {
	[self setPrimitiveAllowPlainTextAuthentication:[NSNumber numberWithBool:value_]];
}





@dynamic allowSSLHostNameMismatch;



- (BOOL)allowSSLHostNameMismatchValue {
	NSNumber *result = [self allowSSLHostNameMismatch];
	return [result boolValue];
}

- (void)setAllowSSLHostNameMismatchValue:(BOOL)value_ {
	[self setAllowSSLHostNameMismatch:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveAllowSSLHostNameMismatchValue {
	NSNumber *result = [self primitiveAllowSSLHostNameMismatch];
	return [result boolValue];
}

- (void)setPrimitiveAllowSSLHostNameMismatchValue:(BOOL)value_ {
	[self setPrimitiveAllowSSLHostNameMismatch:[NSNumber numberWithBool:value_]];
}





@dynamic allowSelfSignedSSL;



- (BOOL)allowSelfSignedSSLValue {
	NSNumber *result = [self allowSelfSignedSSL];
	return [result boolValue];
}

- (void)setAllowSelfSignedSSLValue:(BOOL)value_ {
	[self setAllowSelfSignedSSL:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveAllowSelfSignedSSLValue {
	NSNumber *result = [self primitiveAllowSelfSignedSSL];
	return [result boolValue];
}

- (void)setPrimitiveAllowSelfSignedSSLValue:(BOOL)value_ {
	[self setPrimitiveAllowSelfSignedSSL:[NSNumber numberWithBool:value_]];
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





@dynamic requireTLS;



- (BOOL)requireTLSValue {
	NSNumber *result = [self requireTLS];
	return [result boolValue];
}

- (void)setRequireTLSValue:(BOOL)value_ {
	[self setRequireTLS:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveRequireTLSValue {
	NSNumber *result = [self primitiveRequireTLS];
	return [result boolValue];
}

- (void)setPrimitiveRequireTLSValue:(BOOL)value_ {
	[self setPrimitiveRequireTLS:[NSNumber numberWithBool:value_]];
}





@dynamic sendDeliveryReceipts;



- (BOOL)sendDeliveryReceiptsValue {
	NSNumber *result = [self sendDeliveryReceipts];
	return [result boolValue];
}

- (void)setSendDeliveryReceiptsValue:(BOOL)value_ {
	[self setSendDeliveryReceipts:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveSendDeliveryReceiptsValue {
	NSNumber *result = [self primitiveSendDeliveryReceipts];
	return [result boolValue];
}

- (void)setPrimitiveSendDeliveryReceiptsValue:(BOOL)value_ {
	[self setPrimitiveSendDeliveryReceipts:[NSNumber numberWithBool:value_]];
}





@dynamic sendTypingNotifications;



- (BOOL)sendTypingNotificationsValue {
	NSNumber *result = [self sendTypingNotifications];
	return [result boolValue];
}

- (void)setSendTypingNotificationsValue:(BOOL)value_ {
	[self setSendTypingNotifications:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveSendTypingNotificationsValue {
	NSNumber *result = [self primitiveSendTypingNotifications];
	return [result boolValue];
}

- (void)setPrimitiveSendTypingNotificationsValue:(BOOL)value_ {
	[self setPrimitiveSendTypingNotifications:[NSNumber numberWithBool:value_]];
}





@dynamic subscriptionRequests;

	
- (NSMutableSet*)subscriptionRequestsSet {
	[self willAccessValueForKey:@"subscriptionRequests"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"subscriptionRequests"];
  
	[self didAccessValueForKey:@"subscriptionRequests"];
	return result;
}
	






@end
