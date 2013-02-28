#import "OTRManagedEncryptionStatusMessage.h"


@interface OTRManagedEncryptionStatusMessage ()

// Private interface goes here.

@end


@implementation OTRManagedEncryptionStatusMessage

+(OTRManagedEncryptionStatusMessage *)newEncryptionStatusMessageWithMessage:(NSString *)message buddy:(OTRManagedBuddy *)buddy
{
    OTRManagedEncryptionStatusMessage * encryptionStatusMessage = [OTRManagedEncryptionStatusMessage MR_createEntity];
    encryptionStatusMessage.date = [NSDate date];
    encryptionStatusMessage.isEncryptedValue = NO;
    encryptionStatusMessage.isIncoming = NO;
    
    encryptionStatusMessage.message = message;
    encryptionStatusMessage.buddy = buddy;
    encryptionStatusMessage.encryptionstatusbuddy = buddy;
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}

@end
