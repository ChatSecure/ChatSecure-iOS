#import "OTRManagedStatus.h"
#import "Strings.h"
#import "OTRLog.h"

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
}

+(OTRManagedStatus *)newStatus:(OTRBuddyStatus)newStatus withMessage:(NSString *)newMessage withBuddy:(OTRManagedBuddy *)newBuddy incoming:(BOOL)newIsIncoming inContext:(NSManagedObjectContext *)context
{
    OTRManagedStatus * managedStatus = [OTRManagedStatus MR_createInContext:context];
    NSError *error = nil;
    [context obtainPermanentIDsForObjects:@[managedStatus] error:&error];
    if (error) {
        DDLogError(@"Error obtaining permanent ID for managedStatus: %@", error);
    }
  
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
