#import "_OTRManagedEncryptionStatusMessage.h"
#import "OTRManagedBuddy.h"

@interface OTRManagedEncryptionStatusMessage : _OTRManagedEncryptionStatusMessage {}

+(OTRManagedEncryptionStatusMessage *)newEncryptionStatusMessageWithMessage:(NSString *)message buddy:(OTRManagedBuddy *)buddy;

@end
