#import "_OTRManagedChatMessage.h"

@interface OTRManagedChatMessage : _OTRManagedChatMessage {}


+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus delayedDate:(NSDate *)date inContext:(NSManagedObjectContext *)context;
+(OTRManagedChatMessage *)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus inContext:(NSManagedObjectContext *)context;

+(void)receivedDeliveryReceiptForMessageID:(NSString *)objectIDString;


@end
