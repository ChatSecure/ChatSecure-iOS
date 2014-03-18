// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRXMPPManagedPresenceSubscriptionRequest.h instead.

#import <CoreData/CoreData.h>


extern const struct OTRXMPPManagedPresenceSubscriptionRequestAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *displayName;
	__unsafe_unretained NSString *jid;
} OTRXMPPManagedPresenceSubscriptionRequestAttributes;

extern const struct OTRXMPPManagedPresenceSubscriptionRequestRelationships {
	__unsafe_unretained NSString *xmppAccount;
} OTRXMPPManagedPresenceSubscriptionRequestRelationships;

extern const struct OTRXMPPManagedPresenceSubscriptionRequestFetchedProperties {
} OTRXMPPManagedPresenceSubscriptionRequestFetchedProperties;

@class OTRManagedXMPPAccount;





@interface OTRXMPPManagedPresenceSubscriptionRequestID : NSManagedObjectID {}
@end

@interface _OTRXMPPManagedPresenceSubscriptionRequest : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRXMPPManagedPresenceSubscriptionRequestID*)objectID;





@property (nonatomic, strong) NSDate* date;



//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* displayName;



//- (BOOL)validateDisplayName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* jid;



//- (BOOL)validateJid:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) OTRManagedXMPPAccount *xmppAccount;

//- (BOOL)validateXmppAccount:(id*)value_ error:(NSError**)error_;





@end

@interface _OTRXMPPManagedPresenceSubscriptionRequest (CoreDataGeneratedAccessors)

@end

@interface _OTRXMPPManagedPresenceSubscriptionRequest (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;




- (NSString*)primitiveDisplayName;
- (void)setPrimitiveDisplayName:(NSString*)value;




- (NSString*)primitiveJid;
- (void)setPrimitiveJid:(NSString*)value;





- (OTRManagedXMPPAccount*)primitiveXmppAccount;
- (void)setPrimitiveXmppAccount:(OTRManagedXMPPAccount*)value;


@end
