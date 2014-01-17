#import "OTRManagedChatMessage.h"
#import "OTRUtilities.h"
#import "OTRManagedBuddy.h"


@interface OTRManagedChatMessage ()

// Private interface goes here.

@end


@implementation OTRManagedChatMessage

+(OTRManagedChatMessage*)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage {
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage];
    message.isIncoming = NO;
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    return message;
}

+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage {
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage];
    [message setIsIncomingValue:YES];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    return message;
}

+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus
{
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage];
    message.isEncryptedValue = encryptionStatus;
    [message setIsIncomingValue:YES];
    return message;
    
}

+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus delayedDate:(NSDate *)date
{
    OTRManagedChatMessage * message = [self newMessageFromBuddy:theBuddy message:theMessage encrypted:encryptionStatus];
    if (date) {
        message.date = date;
    }
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    return message;
    
}

+(OTRManagedChatMessage *)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus
{
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage];
    message.isIncomingValue = NO;
    message.isReadValue = YES;
    message.isEncryptedValue = encryptionStatus;
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    return message;
    
}

+(OTRManagedChatMessage*)newMessageWithBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage
{
    OTRManagedChatMessage *managedMessage = [OTRManagedChatMessage MR_createEntity];
    
    managedMessage.uniqueID = [OTRUtilities uniqueString];
    managedMessage.buddy = theBuddy;
    managedMessage.chatBuddy = theBuddy;
    managedMessage.message = [OTRUtilities stripHTML:theMessage];
    managedMessage.date = [NSDate date];
    managedMessage.isEncryptedValue = YES;
    managedMessage.isDeliveredValue = NO;
    
    theBuddy.lastMessageDate = managedMessage.date;
    
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    
    return managedMessage;
}

+(void)receivedDeliveryReceiptForMessageID:(NSString *)objectIDString
{
    NSArray * messages = [OTRManagedChatMessage MR_findByAttribute:OTRManagedChatMessageAttributes.uniqueID withValue:objectIDString];
    [messages enumerateObjectsUsingBlock:^(OTRManagedChatMessage * message, NSUInteger idx, BOOL *stop) {
        message.isDeliveredValue = YES;
    }];
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}

@end
