#import "OTRManagedMessage.h"
#import "OTRManagedBuddy.h"
#import "OTRManagedAccount.h"
#import "NSString+HTML.h"
#import "Strings.h"

#import "OTRLog.h"


@interface OTRManagedMessage ()

// Private interface goes here.

@end


@implementation OTRManagedMessage

// Custom logic goes here.

+ (void) showLocalNotificationForMessage:(OTRManagedMessage*)message {
    OTRManagedMessage *localMessage = [message MR_inThreadContext];
    if (localMessage.isEncryptedValue) {
        DDLogWarn(@"Message was unable to be decrypted, not showing local notification");
        return;
    }
    localMessage.buddy.lastMessageDisconnected = NO;
    NSString * rawMessage = [localMessage.message stringByConvertingHTMLToPlainText];
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    if (![[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        // We are not active, so use a local notification instead
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = REPLY_STRING;
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
        localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",localMessage.buddy.displayName,rawMessage];
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        [userInfo setObject:localMessage.buddy.accountName forKey:kOTRNotificationUserNameKey];
        [userInfo setObject:localMessage.buddy.account.username forKey:kOTRNotificationAccountNameKey];
        [userInfo setObject:localMessage.buddy.account.protocol forKey:kOTRNotificationProtocolKey];
        localNotification.userInfo = userInfo;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        });
    }
}
@end
