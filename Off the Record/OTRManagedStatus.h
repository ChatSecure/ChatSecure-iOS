#import "_OTRManagedStatus.h"
#import "OTRConstants.h"

@interface OTRManagedStatus : _OTRManagedStatus {}


+(OTRManagedStatus *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming;

+(NSString *)statusMessageWithStatus:(OTRBuddyStatus)status;



@end
