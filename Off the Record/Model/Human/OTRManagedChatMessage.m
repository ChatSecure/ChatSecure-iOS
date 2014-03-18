#import "OTRManagedChatMessage.h"
#import "OTRUtilities.h"
#import "OTRManagedBuddy.h"


@interface OTRManagedChatMessage ()

// Private interface goes here.

@end


@implementation OTRManagedChatMessage

+(OTRManagedChatMessage*)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage inContext:(NSManagedObjectContext *)context {
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    message.isIncoming = NO;
    return message;
}

+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage inContext:(NSManagedObjectContext *)context {
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    [message setIsIncomingValue:YES];
    return message;
}

+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus inContext:(NSManagedObjectContext *)context
{
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    message.isEncryptedValue = encryptionStatus;
    [message setIsIncomingValue:YES];
    return message;
    
}

+(OTRManagedChatMessage*)newMessageFromBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus delayedDate:(NSDate *)date inContext:(NSManagedObjectContext *)context
{
    OTRManagedChatMessage * message = [self newMessageFromBuddy:theBuddy message:theMessage encrypted:encryptionStatus inContext:context];
    if (date) {
        message.date = date;
    }
    return message;
    
}

+(OTRManagedChatMessage *)newMessageToBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage encrypted:(BOOL)encryptionStatus inContext:(NSManagedObjectContext *)context
{
    OTRManagedChatMessage *message = [OTRManagedChatMessage newMessageWithBuddy:theBuddy message:theMessage inContext:context];
    message.isIncomingValue = NO;
    message.isReadValue = YES;
    message.isEncryptedValue = encryptionStatus;
    return message;
}

+(OTRManagedChatMessage*)newMessageWithBuddy:(OTRManagedBuddy *)theBuddy message:(NSString *)theMessage inContext:(NSManagedObjectContext *)context
{
    OTRManagedChatMessage *managedMessage = [OTRManagedChatMessage MR_createInContext:context];
    OTRManagedBuddy *localBuddy = [theBuddy MR_inContext:context];
    managedMessage.uniqueID = [OTRUtilities uniqueString];
    managedMessage.buddy = localBuddy;
    managedMessage.chatBuddy = localBuddy;
    managedMessage.message = [OTRUtilities stripHTML:theMessage];
    managedMessage.date = [NSDate date];
    managedMessage.isEncryptedValue = YES;
    managedMessage.isDeliveredValue = NO;
    
    theBuddy.lastMessageDate = managedMessage.date;
    
    return managedMessage;
}

+(void)receivedDeliveryReceiptForMessageID:(NSString *)objectIDString
{
    NSManagedObjectContext * context = [NSManagedObjectContext MR_context];

    NSArray * messages = [OTRManagedChatMessage MR_findByAttribute:OTRManagedChatMessageAttributes.uniqueID withValue:objectIDString inContext:context];
    [messages enumerateObjectsUsingBlock:^(OTRManagedChatMessage * message, NSUInteger idx, BOOL *stop) {
        message.isDeliveredValue = YES;
    }];
    
    [context MR_saveToPersistentStoreAndWait];
}

@end
