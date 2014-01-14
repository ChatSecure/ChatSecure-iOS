#import "_OTRManagedEncryptionMessage.h"
#import "OTRManagedBuddy.h"
#import "OTRConstants.h"

@interface OTRManagedEncryptionMessage : _OTRManagedEncryptionMessage {}


+(OTRManagedEncryptionMessage *)newEncryptionStatus:(OTRKitMessageState)messageState buddy:(OTRManagedBuddy *)buddy;

@end
