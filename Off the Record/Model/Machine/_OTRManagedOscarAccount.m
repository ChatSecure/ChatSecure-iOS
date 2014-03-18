// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedOscarAccount.m instead.

#import "_OTRManagedOscarAccount.h"

const struct OTRManagedOscarAccountAttributes OTRManagedOscarAccountAttributes = {
};

const struct OTRManagedOscarAccountRelationships OTRManagedOscarAccountRelationships = {
};

const struct OTRManagedOscarAccountFetchedProperties OTRManagedOscarAccountFetchedProperties = {
};

@implementation OTRManagedOscarAccountID
@end

@implementation _OTRManagedOscarAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedOscarAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedOscarAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedOscarAccount" inManagedObjectContext:moc_];
}

- (OTRManagedOscarAccountID*)objectID {
	return (OTRManagedOscarAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
