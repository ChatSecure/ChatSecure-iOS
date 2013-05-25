// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRXMPPManagedPresenceSubscriptionRequest.m instead.

#import "_OTRXMPPManagedPresenceSubscriptionRequest.h"

const struct OTRXMPPManagedPresenceSubscriptionRequestAttributes OTRXMPPManagedPresenceSubscriptionRequestAttributes = {
	.date = @"date",
	.displayName = @"displayName",
	.jid = @"jid",
};

const struct OTRXMPPManagedPresenceSubscriptionRequestRelationships OTRXMPPManagedPresenceSubscriptionRequestRelationships = {
	.xmppAccount = @"xmppAccount",
};

const struct OTRXMPPManagedPresenceSubscriptionRequestFetchedProperties OTRXMPPManagedPresenceSubscriptionRequestFetchedProperties = {
};

@implementation OTRXMPPManagedPresenceSubscriptionRequestID
@end

@implementation _OTRXMPPManagedPresenceSubscriptionRequest

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRXMPPManagedPresenceSubscriptionRequest" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRXMPPManagedPresenceSubscriptionRequest";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRXMPPManagedPresenceSubscriptionRequest" inManagedObjectContext:moc_];
}

- (OTRXMPPManagedPresenceSubscriptionRequestID*)objectID {
	return (OTRXMPPManagedPresenceSubscriptionRequestID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic date;






@dynamic displayName;






@dynamic jid;






@dynamic xmppAccount;

	






@end
