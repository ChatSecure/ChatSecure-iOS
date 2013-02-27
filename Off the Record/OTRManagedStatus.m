#import "OTRManagedStatus.h"
#import "Strings.h"


@interface OTRManagedStatus ()

// Private interface goes here.

@end


@implementation OTRManagedStatus

-(void)updateStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage incoming:(BOOL)newIsIncoming
{
    self.date = [NSDate date];
    self.statusValue = newStatus;
    self.isIncomingValue = newIsIncoming;
    self.isEncryptedValue = NO;
    if (![newMessage length]) {
        self.message = [OTRManagedStatus statusMessageWithStatus:newStatus];
    }
    else
    {
        self.message = newMessage;
    }
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
}

+(OTRManagedStatus *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming
{
    OTRManagedStatus * managedStatus = [OTRManagedStatus MR_createEntity];
    managedStatus.statusValue = newStatus;
    
    if (![newMessage length]) {
        managedStatus.message = [OTRManagedStatus statusMessageWithStatus:newStatus];
    }
    else
    {
        managedStatus.message = newMessage;
    }
    
    
    managedStatus.buddy = newBuddy;
    managedStatus.statusbuddy = newBuddy;
    managedStatus.isIncomingValue = newIsIncoming;
    managedStatus.date = [NSDate date];
    managedStatus.isEncryptedValue = NO;
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    
    return managedStatus;
}

+(NSString *)statusMessageWithStatus:(OTRBuddyStatus)status
{
    switch (status) {
        case kOTRBuddyStatusXa:
            return EXTENDED_AWAY_STRING;
            break;
        case kOTRBUddyStatusDnd:
            return DO_NOT_DISTURB_STRING;
            break;
        case kOTRBuddyStatusAway:
            return AWAY_STRING;
            break;
        case kOTRBuddyStatusAvailable:
            return AVAILABLE_STRING;
            break;
        default:
            return OFFLINE_STRING;
            break;
    }
}

@end
