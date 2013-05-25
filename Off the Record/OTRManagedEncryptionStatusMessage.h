#import "_OTRManagedEncryptionStatusMessage.h"
#import "OTRManagedBuddy.h"
#import "OTRConstants.h"

@interface OTRManagedEncryptionStatusMessage : _OTRManagedEncryptionStatusMessage {}

+(OTRManagedEncryptionStatusMessage *)newEncryptionStatus:(OTRKitMessageState)messageState buddy:(OTRManagedBuddy *)buddy;

@end
