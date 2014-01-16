// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedXMPPAccount.h instead.

#import <CoreData/CoreData.h>
#import "OTRManagedAccount.h"

extern const struct OTRManagedXMPPAccountAttributes {
	__unsafe_unretained NSString *domain;
	__unsafe_unretained NSString *port;
} OTRManagedXMPPAccountAttributes;

extern const struct OTRManagedXMPPAccountRelationships {
	__unsafe_unretained NSString *subscriptionRequests;
} OTRManagedXMPPAccountRelationships;

extern const struct OTRManagedXMPPAccountFetchedProperties {
} OTRManagedXMPPAccountFetchedProperties;

@class OTRXMPPManagedPresenceSubscriptionRequest;




@interface OTRManagedXMPPAccountID : NSManagedObjectID {}
@end

@interface _OTRManagedXMPPAccount : OTRManagedAccount {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedXMPPAccountID*)objectID;





@property (nonatomic, strong) NSString* domain;



//- (BOOL)validateDomain:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* port;



@property int16_t portValue;
- (int16_t)portValue;
- (void)setPortValue:(int16_t)value_;

//- (BOOL)validatePort:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *subscriptionRequests;

- (NSMutableSet*)subscriptionRequestsSet;





@end

@interface _OTRManagedXMPPAccount (CoreDataGeneratedAccessors)

- (void)addSubscriptionRequests:(NSSet*)value_;
- (void)removeSubscriptionRequests:(NSSet*)value_;
- (void)addSubscriptionRequestsObject:(OTRXMPPManagedPresenceSubscriptionRequest*)value_;
- (void)removeSubscriptionRequestsObject:(OTRXMPPManagedPresenceSubscriptionRequest*)value_;

@end

@interface _OTRManagedXMPPAccount (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveDomain;
- (void)setPrimitiveDomain:(NSString*)value;




- (NSNumber*)primitivePort;
- (void)setPrimitivePort:(NSNumber*)value;

- (int16_t)primitivePortValue;
- (void)setPrimitivePortValue:(int16_t)value_;





- (NSMutableSet*)primitiveSubscriptionRequests;
- (void)setPrimitiveSubscriptionRequests:(NSMutableSet*)value;


@end
