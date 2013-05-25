#import "OTRManagedEncryptionStatusMessage.h"
#import "Strings.h"


@interface OTRManagedEncryptionStatusMessage ()

// Private interface goes here.

@end


@implementation OTRManagedEncryptionStatusMessage

+(OTRManagedEncryptionStatusMessage *)newEncryptionStatus:(OTRKitMessageState)newEncryptionStatus buddy:(OTRManagedBuddy *)buddy
{
    OTRManagedEncryptionStatusMessage * encryptionStatusMessage = [OTRManagedEncryptionStatusMessage MR_createEntity];
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
            NSLog(@"Unknown Encryption State");
            break;
    }

    
    
    
    encryptionStatusMessage.message = message;
    encryptionStatusMessage.statusValue = newEncryptionStatus;
    encryptionStatusMessage.buddy = buddy;
    encryptionStatusMessage.encryptionstatusbuddy = buddy;
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    
    return encryptionStatusMessage;
}

@end
