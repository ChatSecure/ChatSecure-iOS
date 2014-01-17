#import "OTRManagedStatusMessage.h"
#import "Strings.h"


@interface OTRManagedStatusMessage ()

// Private interface goes here.

@end


@implementation OTRManagedStatusMessage

- (void)updateStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage incoming:(BOOL)newIsIncoming
{
    self.date = [NSDate date];
    self.statusValue = newStatus;
    self.isIncomingValue = newIsIncoming;
    if (![newMessage length]) {
        self.message = [OTRManagedStatusMessage statusMessageWithStatus:newStatus];
    }
    else
    {
        self.message = newMessage;
    }
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}

+ (OTRManagedStatusMessage *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming
{
    OTRManagedStatusMessage * managedStatus = [OTRManagedStatusMessage MR_createEntity];
    managedStatus.statusValue = newStatus;
    
    if (![newMessage length]) {
        managedStatus.message = [OTRManagedStatusMessage statusMessageWithStatus:newStatus];
    }
    else
    {
        managedStatus.message = newMessage;
    }
    
    managedStatus.buddy = newBuddy;
    managedStatus.isIncomingValue = newIsIncoming;
    managedStatus.date = [NSDate date];
    
    /*NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
     [context MR_saveToPersistentStoreAndWait];
     */
    return managedStatus;
}
+ (OTRManagedStatusMessage *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming inContext:(NSManagedObjectContext *)context
{
    OTRManagedStatusMessage * managedStatus = [OTRManagedStatusMessage MR_createInContext:context];
    
    managedStatus.statusValue = newStatus;
    
    if (![newMessage length]) {
        managedStatus.message = [OTRManagedStatusMessage statusMessageWithStatus:newStatus];
    }
    else
    {
        managedStatus.message = newMessage;
    }
    
    
    managedStatus.buddy = newBuddy;
    managedStatus.isIncomingValue = newIsIncoming;
    managedStatus.date = [NSDate date];
    
    [context MR_saveToPersistentStoreAndWait];
    
    return managedStatus;
}

+ (NSString *)statusMessageWithStatus:(OTRBuddyStatus)status
{
    switch (status) {
        case OTRBuddyStatusXa:
            return EXTENDED_AWAY_STRING;
            break;
        case OTRBuddyStatusDnd:
            return DO_NOT_DISTURB_STRING;
            break;
        case OTRBuddyStatusAway:
            return AWAY_STRING;
            break;
        case OTRBuddyStatusAvailable:
            return AVAILABLE_STRING;
            break;
        default:
            return OFFLINE_STRING;
            break;
    }
}

@end
