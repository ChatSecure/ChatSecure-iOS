#import "OTRManagedEncryptionMessage.h"
#import "Strings.h"

#import "OTRLog.h"


@interface OTRManagedEncryptionMessage ()

// Private interface goes here.

@end


@implementation OTRManagedEncryptionMessage

+(OTRManagedEncryptionMessage *)newEncryptionStatus:(OTRKitMessageState)newEncryptionStatus buddy:(OTRManagedBuddy *)buddy inContext:(NSManagedObjectContext *)context
{
    OTRManagedEncryptionMessage * encryptionStatusMessage = [OTRManagedEncryptionMessage MR_createInContext:context];
    
    encryptionStatusMessage.date = [NSDate date];
    encryptionStatusMessage.isEncryptedValue = NO;
    encryptionStatusMessage.isIncoming = NO;
    
    NSString * message = nil;
    
    switch (newEncryptionStatus) {
        case kOTRKitMessageStatePlaintext:
            message = CONVERSATION_NOT_SECURE_WARNING_STRING;
            break;
        case kOTRKitMessageStateEncrypted:
            message = CONVERSATION_SECURE_WARNING_STRING;
            break;
        case kOTRKitMessageStateFinished:
            message = CONVERSATION_NOT_SECURE_WARNING_STRING;
            break;
        default:
            DDLogWarn(@"Unknown Encryption State");
            break;
    }
    
    encryptionStatusMessage.message = message;
    encryptionStatusMessage.statusValue = newEncryptionStatus;
    encryptionStatusMessage.buddy = buddy;
    
    return encryptionStatusMessage;
}

@end
