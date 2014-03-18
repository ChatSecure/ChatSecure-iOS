#import "OTRManagedStatusMessage.h"
#import "Strings.h"
#import "OTRLog.h"

@interface OTRManagedStatusMessage ()

// Private interface goes here.

@end


@implementation OTRManagedStatusMessage

-(void)updateStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage incoming:(BOOL)newIsIncoming
{
    self.date = [NSDate date];
    self.statusValue = newStatus;
    self.isIncomingValue = newIsIncoming;
    self.isEncryptedValue = NO;
    if (![newMessage length]) {
        self.message = [OTRManagedStatusMessage statusMessageWithStatus:newStatus];
    }
    else
    {
        self.message = newMessage;
    }
}

+(OTRManagedStatusMessage *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming inContext:(NSManagedObjectContext *)context
{
    OTRManagedStatusMessage * managedStatus = [OTRManagedStatusMessage MR_createInContext:context];
    NSError *error = nil;
    [context obtainPermanentIDsForObjects:@[managedStatus] error:&error];
    if (error) {
        DDLogError(@"Error obtaining permanent ID for managedStatus: %@", error);
    }
  
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
    managedStatus.isEncryptedValue = NO;
    
    return managedStatus;
}

+(NSString *)statusMessageWithStatus:(OTRBuddyStatus)status
{
    switch (status) {
        case OTRBuddyStatusXa:
            return EXTENDED_AWAY_STRING;
        case OTRBuddyStatusDnd:
            return DO_NOT_DISTURB_STRING;
        case OTRBuddyStatusAway:
            return AWAY_STRING;
        case OTRBuddyStatusAvailable:
            return AVAILABLE_STRING;
        default:
            return OFFLINE_STRING;
    }
}

@end
