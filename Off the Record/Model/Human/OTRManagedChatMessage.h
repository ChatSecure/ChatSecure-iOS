#import "_OTRManagedChatMessage.h"

@interface OTRManagedChatMessage : _OTRManagedChatMessage {}


+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus delayedDate:(NSDate *)date;
+(OTRManagedChatMessage *)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus;

+(void)receivedDeliveryReceiptForMessageID:(NSString *)objectIDString;


@end
