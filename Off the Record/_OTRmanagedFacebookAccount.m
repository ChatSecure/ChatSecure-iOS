// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRmanagedFacebookAccount.m instead.

#import "_OTRmanagedFacebookAccount.h"

const struct OTRmanagedFacebookAccountAttributes OTRmanagedFacebookAccountAttributes = {
};

const struct OTRmanagedFacebookAccountRelationships OTRmanagedFacebookAccountRelationships = {
};

const struct OTRmanagedFacebookAccountFetchedProperties OTRmanagedFacebookAccountFetchedProperties = {
};

@implementation OTRmanagedFacebookAccountID
@end

@implementation _OTRmanagedFacebookAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRmanagedFacebookAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRmanagedFacebookAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRmanagedFacebookAccount" inManagedObjectContext:moc_];
}

- (OTRmanagedFacebookAccountID*)objectID {
	return (OTRmanagedFacebookAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
