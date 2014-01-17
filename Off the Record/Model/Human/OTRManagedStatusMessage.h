#import "_OTRManagedStatusMessage.h"
#import "OTRConstants.h"

@interface OTRManagedStatusMessage : _OTRManagedStatusMessage {}

- (void)updateStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage incoming:(BOOL)newIsIncoming;

+ (OTRManagedStatusMessage *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming;
+ (OTRManagedStatusMessage *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming inContext:(NSManagedObjectContext *)context;

+ (NSString *)statusMessageWithStatus:(OTRBuddyStatus)status;

@end
