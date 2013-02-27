#import "_OTRManagedStatus.h"
#import "OTRConstants.h"

@interface OTRManagedStatus : _OTRManagedStatus {}


-(void)updateStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage incoming:(BOOL)newIsIncoming;

+(OTRManagedStatus *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming;

+(NSString *)statusMessageWithStatus:(OTRBuddyStatus)status;



@end
