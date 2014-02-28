// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedFacebookAccount.m instead.

#import "_OTRManagedFacebookAccount.h"

const struct OTRManagedFacebookAccountAttributes OTRManagedFacebookAccountAttributes = {
};

const struct OTRManagedFacebookAccountRelationships OTRManagedFacebookAccountRelationships = {
};

const struct OTRManagedFacebookAccountFetchedProperties OTRManagedFacebookAccountFetchedProperties = {
};

@implementation OTRManagedFacebookAccountID
@end

@implementation _OTRManagedFacebookAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedFacebookAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedFacebookAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedFacebookAccount" inManagedObjectContext:moc_];
}

- (OTRManagedFacebookAccountID*)objectID {
	return (OTRManagedFacebookAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
