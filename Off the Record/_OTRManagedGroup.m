// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedGroup.m instead.

#import "_OTRManagedGroup.h"

const struct OTRManagedGroupAttributes OTRManagedGroupAttributes = {
	.name = @"name",
};

const struct OTRManagedGroupRelationships OTRManagedGroupRelationships = {
	.buddies = @"buddies",
};

const struct OTRManagedGroupFetchedProperties OTRManagedGroupFetchedProperties = {
};

@implementation OTRManagedGroupID
@end

@implementation _OTRManagedGroup

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedGroup" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedGroup";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedGroup" inManagedObjectContext:moc_];
}

- (OTRManagedGroupID*)objectID {
	return (OTRManagedGroupID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic buddies;

	
- (NSMutableSet*)buddiesSet {
	[self willAccessValueForKey:@"buddies"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"buddies"];
  
	[self didAccessValueForKey:@"buddies"];
	return result;
}
	






@end
