// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedXMPPTorAccount.m instead.

#import "_OTRManagedXMPPTorAccount.h"

const struct OTRManagedXMPPTorAccountAttributes OTRManagedXMPPTorAccountAttributes = {
};

const struct OTRManagedXMPPTorAccountRelationships OTRManagedXMPPTorAccountRelationships = {
};

const struct OTRManagedXMPPTorAccountFetchedProperties OTRManagedXMPPTorAccountFetchedProperties = {
};

@implementation OTRManagedXMPPTorAccountID
@end

@implementation _OTRManagedXMPPTorAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedXMPPTorAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedXMPPTorAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedXMPPTorAccount" inManagedObjectContext:moc_];
}

- (OTRManagedXMPPTorAccountID*)objectID {
	return (OTRManagedXMPPTorAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
