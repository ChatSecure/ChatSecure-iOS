#import "OTRManagedEncryptionStatusMessage.h"
#import "Strings.h"

#import "OTRLog.h"


@interface OTRManagedEncryptionStatusMessage ()

// Private interface goes here.

@end


@implementation OTRManagedEncryptionStatusMessage

+(OTRManagedEncryptionStatusMessage *)newEncryptionStatus:(OTRKitMessageState)newEncryptionStatus buddy:(OTRManagedBuddy *)buddy inContext:(NSManagedObjectContext *)context
{
    OTRManagedEncryptionStatusMessage * encryptionStatusMessage = [OTRManagedEncryptionStatusMessage MR_createInContext:context];
    NSError *error = nil;
    [context obtainPermanentIDsForObjects:@[encryptionStatusMessage] error:&error];
    if (error) {
        DDLogError(@"Error obtaining permanent ID for OTRManagedEncryptionStatusMessage: %@", error);
    }
    
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
    encryptionStatusMessage.encryptionstatusbuddy = buddy;
    
    return encryptionStatusMessage;
}

@end
