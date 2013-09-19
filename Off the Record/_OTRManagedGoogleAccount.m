// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedGoogleAccount.m instead.

#import "_OTRManagedGoogleAccount.h"

const struct OTRManagedGoogleAccountAttributes OTRManagedGoogleAccountAttributes = {
};

const struct OTRManagedGoogleAccountRelationships OTRManagedGoogleAccountRelationships = {
};

const struct OTRManagedGoogleAccountFetchedProperties OTRManagedGoogleAccountFetchedProperties = {
};

@implementation OTRManagedGoogleAccountID
@end

@implementation _OTRManagedGoogleAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedGoogleAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedGoogleAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedGoogleAccount" inManagedObjectContext:moc_];
}

- (OTRManagedGoogleAccountID*)objectID {
	return (OTRManagedGoogleAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
