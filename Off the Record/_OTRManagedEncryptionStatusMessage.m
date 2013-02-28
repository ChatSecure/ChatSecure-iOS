// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedEncryptionStatusMessage.m instead.

#import "_OTRManagedEncryptionStatusMessage.h"

const struct OTRManagedEncryptionStatusMessageAttributes OTRManagedEncryptionStatusMessageAttributes = {
};

const struct OTRManagedEncryptionStatusMessageRelationships OTRManagedEncryptionStatusMessageRelationships = {
	.encryptionstatusbuddy = @"encryptionstatusbuddy",
};

const struct OTRManagedEncryptionStatusMessageFetchedProperties OTRManagedEncryptionStatusMessageFetchedProperties = {
};

@implementation OTRManagedEncryptionStatusMessageID
@end

@implementation _OTRManagedEncryptionStatusMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"OTRManagedEncryptionStatusMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"OTRManagedEncryptionStatusMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"OTRManagedEncryptionStatusMessage" inManagedObjectContext:moc_];
}

- (OTRManagedEncryptionStatusMessageID*)objectID {
	return (OTRManagedEncryptionStatusMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic encryptionstatusbuddy;

	






@end
