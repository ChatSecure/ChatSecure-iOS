//
//  OTRProtocolManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRProtocolManager.h"

static OTRProtocolManager *sharedManager = nil;

@implementation OTRProtocolManager

@synthesize oscarManager;
@synthesize encryptionManager;
@synthesize xmppManager;
@synthesize buddyList;

-(id)init
{
    self = [super init];
    if(self)
    {
        oscarManager = [[OTROscarManager alloc] init];
        xmppManager = [[OTRXMPPManager alloc] init];
        encryptionManager = [[OTREncryptionManager alloc] init];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(sendMessage:)
         name:@"SendMessageNotification"
         object:nil ];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(buddyListUpdate)
         name:@"BuddyListUpdateNotification"
         object:nil ];
        
        
        buddyList = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark Singleton Object Methods

+ (OTRProtocolManager*)sharedInstance {
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [[self alloc] init];
        }
    }
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [super allocWithZone:zone];
            return sharedManager;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

/*- (void)release {
 //do nothing
 }*/

- (id)autorelease {
    return self;
}


-(void)sendMessage:(NSNotification *)notification
{
    OTRMessage *message = [notification.userInfo objectForKey:@"message"];
    NSString *protocol = message.protocol;
    
    NSLog(@"send message (%@): %@", protocol, message.message);
    
    
    if([protocol isEqualToString:@"xmpp"])
    {
        [self sendMessageXMPP:message];
    }
    else if([protocol isEqualToString:@"prpl-oscar"])
    {
        [self sendMessageOSCAR:message];
    }
}

-(void)sendMessageOSCAR:(OTRMessage *)theMessage
{
    NSString *recipient = theMessage.recipient;
    NSString *message = theMessage.message;
    
    AIMSessionManager *theSession = [oscarManager.theSession retain];
    AIMMessage * msg = [AIMMessage messageWithBuddy:[theSession.session.buddyList buddyWithUsername:recipient] message:message];
    
    // use delay to prevent OSCAR rate-limiting problem
    //NSDate *future = [NSDate dateWithTimeIntervalSinceNow: delay ];
    //[NSThread sleepUntilDate:future];
    
	[theSession.messageHandler sendMessage:msg];
    
    [theSession release];
}

-(void)sendMessageXMPP:(OTRMessage *)theMessage
{
    NSString *messageStr = theMessage.message;
	
	if([messageStr length] > 0)
	{
		NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
		[body setStringValue:messageStr];
		
		NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
		[message addAttributeWithName:@"type" stringValue:@"chat"];
		[message addAttributeWithName:@"to" stringValue:theMessage.recipient];
		[message addChild:body];
		
		[xmppManager.xmppStream sendElement:message];		
	}
}

-(void)buddyListUpdate
{
    [buddyList removeAllObjects];
    
    if(oscarManager.buddyList)
    {
        AIMBlist *blist = oscarManager.buddyList;
        

        
        for(AIMBlistGroup *group in blist.groups)
        {
            NSMutableDictionary *groupDictionary = [[NSMutableDictionary alloc] initWithCapacity:[blist.groups count]];
            
            [groupDictionary setObject:group.name forKey:@"group_name"];
            
            NSMutableDictionary *buddyDictionary = [[NSMutableDictionary alloc] initWithCapacity:[group.buddies count]];
            
            for(AIMBlistBuddy *buddy in group.buddies)
            {
                NSMutableDictionary *buddyData = [[NSMutableDictionary alloc] init];
                [buddyData setObject:buddy.username forKey:@"buddy_name"];
                [buddyData setObject:@"prpl-oscar" forKey:@"protocol"];
                
                switch (buddy.status.statusType) 
                {
                    case AIMBuddyStatusAvailable:
                        [buddyData setObject:@"Available" forKey:@"status"];
                        break;
                    case AIMBuddyStatusAway:
                        [buddyData setObject:@"Away" forKey:@"status"];
                        break;
                    default:
                        [buddyData setObject:@"Offline" forKey:@"status"];
                        break;
                }
                
                [buddyDictionary setObject:buddyData forKey:buddy.username];
            }
            [groupDictionary setObject:buddyDictionary forKey:@"group_data"];
            
            [buddyList setObject:groupDictionary forKey:[NSString stringWithFormat:@"AIM - %@", group.name]];
        }
    }
    
    if(xmppManager.isXmppConnected)
    {
        NSFetchedResultsController *frc = [xmppManager fetchedResultsController];
        
        NSArray *sections = [frc sections];

        int sectionsCount = [sections count];
        
        NSMutableArray *rowsInSection = [[NSMutableArray alloc] initWithCapacity:sectionsCount];
                
        for(int sectionIndex = 0; sectionIndex < sectionsCount; sectionIndex++)
        {
            id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
            [rowsInSection addObject:[NSNumber numberWithInt:sectionInfo.numberOfObjects]];
        }
        
        for(int i = 0; i < sectionsCount; i++)
        {
            NSMutableDictionary *groupDictionary = [[NSMutableDictionary alloc] initWithCapacity:sectionsCount];
            
            NSString *sectionName;
            NSString *status;
            switch (i) {
                case 0:
                    sectionName = @"XMPP - Available";
                    status = @"Available";
                    break;
                case 1:
                    sectionName = @"XMPP - Away";
                    status = @"Away";
                default:
                    sectionName = @"XMPP - Offline";
                    status = @"Offline";
                    break;
            }
            [groupDictionary setObject:sectionName forKey:@"group_name"];
            
            NSMutableDictionary *buddyDictionary = [[NSMutableDictionary alloc] initWithCapacity:[[rowsInSection objectAtIndex:i] intValue]];

            for(int j = 0; j < [[rowsInSection objectAtIndex:i] intValue]; j++)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                
                XMPPUserCoreDataStorageObject *user = [frc objectAtIndexPath:indexPath]; 
                
                NSMutableDictionary *buddyData = [[NSMutableDictionary alloc] init];
                [buddyData setObject:[user.displayName copy] forKey:@"buddy_name"];
                [buddyData setObject:@"xmpp" forKey:@"protocol"];
                [buddyData setObject:status forKey:@"status"];

                
                [buddyDictionary setObject:buddyData forKey:user.displayName];
            }
            [groupDictionary setObject:buddyDictionary forKey:@"group_data"];
            
            [buddyList setObject:groupDictionary forKey:[NSString stringWithFormat:@"XMPP - %@", sectionName]];

        }
    }
}

-(NSString*)accountNameForProtocol:(NSString*)protocol
{
    if([protocol isEqualToString:@"prpl-oscar"])
    {
        return oscarManager.accountName;
    }
    else if([protocol isEqualToString:@"xmpp"])
    {
        return [xmppManager accountName];
    }
    return nil;
}

@end
