// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to OTRManagedAccount.h instead.

#import <CoreData/CoreData.h>


extern const struct OTRManagedAccountAttributes {
	__unsafe_unretained NSString *autologin;
	__unsafe_unretained NSString *displayName;
	__unsafe_unretained NSString *protocol;
	__unsafe_unretained NSString *rememberPassword;
	__unsafe_unretained NSString *uniqueIdentifier;
	__unsafe_unretained NSString *username;
} OTRManagedAccountAttributes;

extern const struct OTRManagedAccountRelationships {
	__unsafe_unretained NSString *buddies;
} OTRManagedAccountRelationships;

extern const struct OTRManagedAccountFetchedProperties {
} OTRManagedAccountFetchedProperties;

@class OTRManagedBuddy;








@interface OTRManagedAccountID : NSManagedObjectID {}
@end

@interface _OTRManagedAccount : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (OTRManagedAccountID*)objectID;





@property (nonatomic, strong) NSNumber* autologin;



@property BOOL autologinValue;
- (BOOL)autologinValue;
- (void)setAutologinValue:(BOOL)value_;

//- (BOOL)validateAutologin:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* displayName;



//- (BOOL)validateDisplayName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* protocol;



//- (BOOL)validateProtocol:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* rememberPassword;



@property BOOL rememberPasswordValue;
- (BOOL)rememberPasswordValue;
- (void)setRememberPasswordValue:(BOOL)value_;

//- (BOOL)validateRememberPassword:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* uniqueIdentifier;



//- (BOOL)validateUniqueIdentifier:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* username;



//- (BOOL)validateUsername:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *buddies;

- (NSMutableSet*)buddiesSet;





@end

@interface _OTRManagedAccount (CoreDataGeneratedAccessors)

- (void)addBuddies:(NSSet*)value_;
- (void)removeBuddies:(NSSet*)value_;
- (void)addBuddiesObject:(OTRManagedBuddy*)value_;
- (void)removeBuddiesObject:(OTRManagedBuddy*)value_;

@end

@interface _OTRManagedAccount (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveAutologin;
- (void)setPrimitiveAutologin:(NSNumber*)value;

- (BOOL)primitiveAutologinValue;
- (void)setPrimitiveAutologinValue:(BOOL)value_;




- (NSString*)primitiveDisplayName;
- (void)setPrimitiveDisplayName:(NSString*)value;




- (NSString*)primitiveProtocol;
- (void)setPrimitiveProtocol:(NSString*)value;




- (NSNumber*)primitiveRememberPassword;
- (void)setPrimitiveRememberPassword:(NSNumber*)value;

- (BOOL)primitiveRememberPasswordValue;
- (void)setPrimitiveRememberPasswordValue:(BOOL)value_;




- (NSString*)primitiveUniqueIdentifier;
- (void)setPrimitiveUniqueIdentifier:(NSString*)value;




- (NSString*)primitiveUsername;
- (void)setPrimitiveUsername:(NSString*)value;





- (NSMutableSet*)primitiveBuddies;
- (void)setPrimitiveBuddies:(NSMutableSet*)value;


@end
