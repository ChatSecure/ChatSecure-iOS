// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedOAuthAccount.m instead.

#import "_OTRManagedOAuthAccount.h"

const struct OTRManagedOAuthAccountAttributes OTRManagedOAuthAccountAttributes = {
};

const struct OTRManagedOAuthAccountRelationships OTRManagedOAuthAccountRelationships = {
};

const struct OTRManagedOAuthAccountFetchedProperties OTRManagedOAuthAccountFetchedProperties = {
};

@implementation OTRManagedOAuthAccountID
@end

@implementation _OTRManagedOAuthAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedOAuthAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedOAuthAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedOAuthAccount" inManagedObjectContext:moc_];
}

- (OTRManagedOAuthAccountID*)objectID {
	return (OTRManagedOAuthAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
