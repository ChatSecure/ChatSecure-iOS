// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRPushAccount.m instead.

#import "_OTRPushAccount.h"

const struct OTRPushAccountAttributes OTRPushAccountAttributes = {
};

const struct OTRPushAccountRelationships OTRPushAccountRelationships = {
};

const struct OTRPushAccountFetchedProperties OTRPushAccountFetchedProperties = {
};

@implementation OTRPushAccountID
@end

@implementation _OTRPushAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRPushAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRPushAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRPushAccount" inManagedObjectContext:moc_];
}

- (OTRPushAccountID*)objectID {
	return (OTRPushAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}









@end
