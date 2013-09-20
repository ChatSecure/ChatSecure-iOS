//
//  OTRXMPPManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/7/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRXMPPManager.h"

#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+XEP_0085.h"
#import "NSXMLElement+XEP_0203.h"
#import "Strings.h"
#import "OTRXMPPManagedPresenceSubscriptionRequest.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

#import <CFNetwork/CFNetwork.h>

#import "OTRSettingsManager.h"
#import "OTRConstants.h"
#import "OTRProtocolManager.h"
#include <stdlib.h>
#import "XMPPXFacebookPlatformAuthentication.h"
#import "XMPPXOATH2Google.h"
#import "OTRConstants.h"
#import "OTRUtilities.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#endif

@interface OTRXMPPManager()

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;
- (void)failedToConnect:(id)error;

@end


@implementation OTRXMPPManager

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;
@synthesize isXmppConnected;
@synthesize account;
@synthesize buddyTimers;

- (id) initWithAccount:(OTRManagedAccount *)newAccount {
    self = [super init];
    
    if(self)
    {
        self.account = (OTRManagedXMPPAccount*)newAccount;

        // Configure logging framework
        backgroundQueue = dispatch_queue_create("buddy.background", NULL);
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        
        // Setup the XMPP stream
        [self setupStream];
        
        //[self setupStream];
        buddyTimers = [NSMutableDictionary dictionary];
        
    }
    
    return self;
}

- (void)dealloc
{
	[self teardownStream];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = [self managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = @[sd1,sd2];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:nil
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			NSLog(@"Error performing fetch: %@", error);
		}
        
	}
	
	return fetchedResultsController;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext_roster
{
	NSAssert([NSThread isMainThread],
	         @"NSManagedObjectContext is not thread safe. It must always be used on the same thread/queue");
	
	if (managedObjectContext_roster == nil)
	{
		managedObjectContext_roster = [[NSManagedObjectContext alloc] init];
		
		NSPersistentStoreCoordinator *psc = [xmppRosterStorage persistentStoreCoordinator];
		[managedObjectContext_roster setPersistentStoreCoordinator:psc];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(contextDidSave:)
		                                             name:NSManagedObjectContextDidSaveNotification
		                                           object:nil];
	}
	
	return managedObjectContext_roster;
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	NSAssert([NSThread isMainThread],
	         @"NSManagedObjectContext is not thread safe. It must always be used on the same thread/queue");
	
	if (managedObjectContext_capabilities == nil)
	{
		managedObjectContext_capabilities = [[NSManagedObjectContext alloc] init];
		
		NSPersistentStoreCoordinator *psc = [xmppCapabilitiesStorage persistentStoreCoordinator];
		[managedObjectContext_roster setPersistentStoreCoordinator:psc];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(contextDidSave:)
		                                             name:NSManagedObjectContextDidSaveNotification
		                                           object:nil];
	}
	
	return managedObjectContext_capabilities;
}

- (void)contextDidSave:(NSNotification *)notification
{
	NSManagedObjectContext *sender = (NSManagedObjectContext *)[notification object];
	
	if (sender != managedObjectContext_roster &&
	    [sender persistentStoreCoordinator] == [managedObjectContext_roster persistentStoreCoordinator])
	{
		DDLogVerbose(@"%@: %@ - Merging changes into managedObjectContext_roster", THIS_FILE, THIS_METHOD);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[managedObjectContext_roster mergeChangesFromContextDidSaveNotification:notification];
		});
    }
	
	if (sender != managedObjectContext_capabilities &&
	    [sender persistentStoreCoordinator] == [managedObjectContext_capabilities persistentStoreCoordinator])
	{
		DDLogVerbose(@"%@: %@ - Merging changes into managedObjectContext_capabilities", THIS_FILE, THIS_METHOD);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[managedObjectContext_capabilities mergeChangesFromContextDidSaveNotification:notification];
		});
	}
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    dispatch_async(backgroundQueue, ^{
        if ([controller isEqual:self.fetchedResultsController]) {
            XMPPUserCoreDataStorageObject * user = (XMPPUserCoreDataStorageObject *)anObject;
            OTRManagedXMPPAccount * localAccount = [self.account MR_inThreadContext];
            
            OTRManagedBuddy * buddy = nil;
            if ([[user jid] full]) {
                buddy =[OTRManagedBuddy fetchOrCreateWithName:[[user jid] full] account:localAccount];
            }
            
            switch (type) {
                case NSFetchedResultsChangeDelete:
                    NSLog(@"deleted roster");
                    
                    //user = [controller objectAtIndexPath:indexPath];
                    break;
                default:
                    break;
            }
            
            if (buddy) {
                buddy.displayName = user.displayName;
                buddy.accountName = [[user jid] full];
                buddy.account = localAccount;
                
                if (user.photo) {
                    buddy.photo = user.photo;
                }
                
                
                [buddy removeGroups:buddy.groups];
                
                if (![user.groups count]) {
                    [buddy addToGroup:DEFAULT_BUDDY_GROUP_STRING];
                }
                else{
                    for(XMPPGroupCoreDataStorageObject * xmppGroup in user.groups)
                    {
                        [buddy addToGroup:xmppGroup.name];
                    }
                }
                
                XMPPResourceCoreDataStorageObject * primaryResource = user.primaryResource;
                OTRBuddyStatus buddyStatus;
                
                if (primaryResource) {
                    switch (primaryResource.intShow)
                    {
                        case 0  :
                            buddyStatus = kOTRBUddyStatusDnd;
                            break;
                        case 1  :
                            buddyStatus = kOTRBuddyStatusXa;
                            break;
                        case 2  :
                            buddyStatus = kOTRBuddyStatusAway;
                            break;
                        case 3  :
                            buddyStatus = kOTRBuddyStatusAvailable;
                            break;
                        case 4  :
                            buddyStatus = kOTRBuddyStatusAvailable;
                            break;
                        default :
                            buddyStatus = kOTRBuddyStatusOffline;
                            break;
                    }
                }
                else
                {
                    buddyStatus = kOTRBuddyStatusOffline;
                }
                
                if (user.isPendingApproval) {
                    [buddy newStatusMessage:PENDING_APPROVAL_STRING status:buddyStatus incoming:YES];
                }
                else{
                    [buddy newStatusMessage:user.primaryResource.status status:buddyStatus incoming:YES];
                }
                
                
                
                
            }
            [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveOnlySelfAndWait];
            /*[localContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (error) {
                    NSLog(@"Error saving to disk: %@", error.userInfo);
                }
            }];
             */

        }
    });

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setupStream
{
	NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	// 
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	if (self.account.accountType == OTRAccountTypeFacebook) {
        xmppStream = [[XMPPStream alloc] initWithFacebookAppId:FACEBOOK_APP_ID];
    }
    else{
        xmppStream = [[XMPPStream alloc] init];
    }
    
    
    
    //Makes sure not allow any sending of password in plain text
    
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		// 
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	// 
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	// 
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
    
    //NSLog(@"Unique Identifier: %@",self.account.uniqueIdentifier);
	
    //xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:self.account.uniqueIdentifier];
    //  xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
	
	xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
	
	// Setup vCard support
	// 
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
	
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
	
	// Setup capabilities
	// 
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	// 
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	// 
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
	xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    
    xmppCapabilities.autoFetchHashedCapabilities = YES;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
	// Activate xmpp modules
    
	[xmppReconnect         activate:xmppStream];
	[xmppRoster            activate:xmppStream];
	[xmppvCardTempModule   activate:xmppStream];
	[xmppvCardAvatarModule activate:xmppStream];
	[xmppCapabilities      activate:xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppCapabilities addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
	// Optional:
	// 
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	// 
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	// 
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];	
	
    
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = account.shouldAllowSelfSignedSSL;
	allowSSLHostNameMismatch = account.shouldAllowSSLHostNameMismatch;
}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
	
	[xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
// 
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
// 
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
// 
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

- (void)goOnline
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolLoginSuccess object:self];
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[[self xmppStream] sendElement:presence];
    [self fetchedResultsController];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

- (void)failedToConnect:(id)error
{
    if (error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kOTRProtocolLoginFail object:self userInfo:@{KOTRProtocolLoginFailErrorKey:error}];
    }
    else {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kOTRProtocolLoginFail object:self];
    }
    
}

///////////////////////////////
#pragma mark Capabilities Collected
- (void)xmppCapabilities:(XMPPCapabilities *)sender collectingMyCapabilities:(NSXMLElement *)query
{
    if(account.sendDeliveryReceipts)
    {
        NSXMLElement * deliveryReceiptsFeature = [NSXMLElement elementWithName:@"feature"];
        [deliveryReceiptsFeature addAttributeWithName:@"var" stringValue:@"urn:xmpp:receipts"];
        [query addChild:deliveryReceiptsFeature];
    }
    
    NSXMLElement * chatStateFeature = [NSXMLElement elementWithName:@"feature"];
	[chatStateFeature addAttributeWithName:@"var" stringValue:@"http://jabber.org/protocol/chatstates"];
    [query addChild:chatStateFeature];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connectWithJID:(NSString*) myJID password:(NSString*)myPassword;
{
    //NSLog(@"myJID %@",myJID);
	if (![xmppStream isDisconnected]) {
		return YES;
	}
    xmppStream.autoStartTLS = YES;
    
	//
	// If you don't want to use the Settings view to set the JID, 
	// uncomment the section below to hard code a JID and password.
	//
	// Replace me with the proper JID and password:
	//	myJID = @"user@gmail.com/xmppframework";
	//	myPassword = @"";
    
	if (myJID == nil || myPassword == nil) {
		DDLogWarn(@"JID and password must be set before connecting!");
        
		return NO;
	}
    
    int r = arc4random() % 99999;
    
    NSString * resource = [NSString stringWithFormat:@"%@%d",kOTRXMPPResource,r];
    
    JID = [XMPPJID jidWithString:myJID resource:resource];
    
	[xmppStream setMyJID:JID];
    [xmppStream setHostName:self.account.domain];
    [xmppStream setHostPort:self.account.portValue];
	password = myPassword;
    
	NSError *error = nil;
	if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting" 
		                                                    message:@"See console for error details." 
		                                                   delegate:nil 
		                                          cancelButtonTitle:@"Ok" 
		                                          otherButtonTitles:nil];
		[alertView show];
        
		DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
	return YES;
}

- (void)disconnect {
    [self goOffline];
    
    [xmppStream disconnect];
    
    [self.account setAllBuddiesStatuts:kOTRBuddyStatusOffline];
    self.account.isConnectedValue = NO;
    
    if([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect])
    {
        [self.account deleteAllConversationsForAccount];
    }
    
    
    
    [self.xmppRosterStorage clearAllUsersAndResourcesForXMPPStream:self.xmppStream];
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket 
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [settings setObject:[OTRUtilities cipherSuites] forKey:GCDAsyncSocketSSLCipherSuites];

	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = xmppStream.hostName;
		NSString *virtualDomain = [xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:kOTRGoogleTalkDomain])
		{
			if ([virtualDomain isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualDomain;
			}
			else
			{
				expectedCertName = serverDomain;
			}
		}
		else if (serverDomain == nil)
		{
			expectedCertName = virtualDomain;
		}
		else
		{
			expectedCertName = serverDomain;
		}
		
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	
	NSError *error = nil;
    
    if ([sender supportsXFacebookPlatformAuthentication]) {
        
        isXmppConnected = [sender authenticateWithFacebookAccessToken:password error:&error];
        return;
    }
    else if ([sender supportsXOAUTH2GoogleAuthentication] && self.account.accountType == OTRAccountTypeGoogleTalk) {
        isXmppConnected = [sender authenticateWithGoogleAccessToken:password error:&error];
        return;
    }
	else if (![[self xmppStream] authenticateWithPassword:password error:&error])
	{
        isXmppConnected = NO;
        return;
	}
    
    isXmppConnected = YES;
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	[self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self failedToConnect:error];
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [iq elementID]);
	
	return NO;
}

-(OTRManagedBuddy *)buddyWithMessage:(XMPPMessage *)message
{
    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
                                                             xmppStream:xmppStream
                                                   managedObjectContext:[self managedObjectContext_roster]];
    
    return [OTRManagedBuddy fetchOrCreateWithName:[user.jid full] account:self.account];
}


- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	// A simple example of inbound message handling.
    if([message hasChatState] && ![message isErrorMessage])
    {
        OTRManagedBuddy * messageBuddy = [self buddyWithMessage:message];
        if([message isComposingChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateComposing];
        else if([message isPausedChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStatePaused];
        else if([message isActiveChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateActive];
        else if([message isInactiveChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateInactive];
        else if([message isGoneChatState])
            [messageBuddy receiveChatStateMessage:kOTRChatStateGone];
    }
    
    //Posible needs a setting to turn on and off
    if([message hasReceiptRequest] && self.account.sendDeliveryReceipts && ![message isErrorMessage])
    {
        XMPPMessage * responseMessage = [message generateReceiptResponse];
        [xmppStream sendElement:responseMessage];
    }
    
    if ([message hasReceiptResponse] && ![message isErrorMessage]) {
        
        XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
                                                                 xmppStream:xmppStream
                                                       managedObjectContext:[self managedObjectContext_roster]];
        
        OTRManagedBuddy * messageBuddy = [OTRManagedBuddy fetchOrCreateWithName:[user.jid full] account:self.account];
        
        [messageBuddy receiveReceiptResonse:[message receiptResponseID]];
    }
    
	if ([message isMessageWithBody] && ![message isErrorMessage])
	{
        NSString *body = [[message elementForName:@"body"] stringValue];
        
        OTRManagedBuddy * messageBuddy = [self buddyWithMessage:message];
        
        NSDate * date = [message delayedDeliveryDate];
        
        OTRManagedMessage *otrMessage = [OTRManagedMessage newMessageFromBuddy:messageBuddy message:body encrypted:YES delayedDate:date];
        [OTRCodec decodeMessage:otrMessage];
        
        if(otrMessage && !otrMessage.isEncryptedValue)
        {
            [messageBuddy receiveMessage:otrMessage.message];
            
        }
	}
    
}
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@\nType: %@\nShow: %@\nStatus: %@", THIS_FILE, THIS_METHOD, [presence from], [presence type], [presence show],[presence status]);
    /*
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRStatusUpdate
     object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys: [[presence from]bare] ,@"user", nil]];
     */
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRProtocolDiconnect object:self]; 
	
	if (!isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        [self failedToConnect:error];
	}
    else {
        //Lost connection
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
	                                                         xmppStream:xmppStream
	                                               managedObjectContext:[self managedObjectContext_roster]];
	
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
    
    OTRXMPPManagedPresenceSubscriptionRequest * subRequest = [OTRXMPPManagedPresenceSubscriptionRequest fetchOrCreateWith:jidStrBare account:self.account];
	
	if (![displayName isEqualToString:jidStrBare] && [displayName length])
	{
        subRequest.displayName = displayName;
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else
	{
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
    
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];

    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark OTRProtocol 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sendMessage:(OTRManagedMessage*)theMessage
{
    NSString *messageStr = theMessage.message;
    
    if ([messageStr length] >0) 
    {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
		[body setStringValue:messageStr];
		
		NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
		[message addAttributeWithName:@"type" stringValue:@"chat"];
		[message addAttributeWithName:@"to" stringValue:theMessage.buddy.accountName];
        NSString * messageID = [NSString stringWithFormat:@"%@",theMessage.uniqueID];
        [message addAttributeWithName:@"id" stringValue:messageID];
        
        NSXMLElement * receiptRequest = [NSXMLElement elementWithName:@"request"];
        [receiptRequest addAttributeWithName:@"xmlns" stringValue:@"urn:xmpp:receipts"];
        [message addChild:receiptRequest];
        
		[message addChild:body];
        
        XMPPMessage * xMessage = [XMPPMessage messageFromElement:message];
        [xMessage addActiveChatState];
		
		[xmppStream sendElement:message];
       
    }
}

- (NSString*) accountName
{
    return [JID full];
    
}

- (NSString*) type {
    return kOTRProtocolTypeXMPP;
}

-(void)connectWithPassword:(NSString *)myPassword
{
    [self connectWithJID:self.account.username password:myPassword];
}

-(void)sendChatState:(OTRChatState)chatState withBuddyID:(NSManagedObjectID *)managedBuddyObjectID
{
    
    OTRManagedBuddy * buddy = [self managedBuddyWithObjectID:managedBuddyObjectID];
    

    if (buddy.lastSentChatState.intValue == chatState) {
        return;
    }
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:buddy.accountName];
    XMPPMessage * xMessage = [XMPPMessage messageFromElement:message];
    
    BOOL shouldSend = YES;
    
    if (chatState == kOTRChatStateActive) {
        [[self pausedChatStateTimerForBuddyObjectID:managedBuddyObjectID] invalidate];
        [self restartInactiveChatStateTimerForBuddyObjectID:managedBuddyObjectID];
        [xMessage addActiveChatState];
    }
    else if (chatState == kOTRChatStateComposing)
    {
        if(buddy.lastSentChatState.intValue !=kOTRChatStateComposing)
            [xMessage addComposingChatState];
        else
            shouldSend = NO;
        
        [self restartPausedChatStateTimerForBuddyObjectID:managedBuddyObjectID];
        [[self inactiveChatStateTimerForBuddyObjectID:managedBuddyObjectID] invalidate];
        
    }
    else if(chatState == kOTRChatStateInactive)
    {
        if(buddy.lastSentChatState.intValue != kOTRChatStateInactive)
            [xMessage addInactiveChatState];
        else
            shouldSend = NO;
    }
    else if (chatState == kOTRChatStatePaused)
    {
        [xMessage addPausedChatState];
    }
    else if (chatState == kOTRChatStateGone)
    {
        [xMessage addGoneChatState];
    }
    else
    {
        shouldSend = NO;
    }
    
    if(shouldSend)
    {
        [buddy setLastSentChatStateValue:chatState];
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
        [context MR_saveToPersistentStoreAndWait];
        [xmppStream sendElement:message];
    }
}

- (void) addBuddy:(OTRManagedBuddy *)newBuddy
{
    [newBuddy addToGroup:@"Buddies"];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];
    XMPPJID * newJID = [XMPPJID jidWithString:newBuddy.accountName];
    [xmppRoster addUser:newJID withNickname:newBuddy.displayName];
}
- (void) setDisplayName:(NSString *) newDisplayName forBuddy:(OTRManagedBuddy *)buddy
{
    XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
    [xmppRoster setNickname:newDisplayName forUser:jid];
    
}
-(void)removeBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
        [xmppRoster removeUser:jid];
        [buddy MR_deleteEntity];
    }
    
    NSManagedObjectContext * context = [NSManagedObjectContext MR_contextForCurrentThread];
    [context MR_saveToPersistentStoreAndWait];



}
-(void)blockBuddies:(NSArray *)buddies
{
    for (OTRManagedBuddy * buddy in buddies){
        XMPPJID * jid = [XMPPJID jidWithString:buddy.accountName];
        [xmppRoster revokePresencePermissionFromUser:jid];
    }
}

//Chat State
-(OTRManagedBuddy *)managedBuddyWithObjectID:(NSManagedObjectID *)managedBuddyObjectID
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    NSError * error = nil;
    OTRManagedBuddy * managedBuddy = (OTRManagedBuddy *)[context existingObjectWithID:managedBuddyObjectID error:&error];
    if (error) {
        NSLog(@"Error Fetching Buddy: %@",error);
    }
    return managedBuddy;
    
}
-(OTRXMPPBudyTimers *)buddyTimersForBuddyObjectID:(NSManagedObjectID *)
managedBuddyObjectID
{
    OTRXMPPBudyTimers * timers = (OTRXMPPBudyTimers *)[buddyTimers objectForKey:managedBuddyObjectID];
    return timers;
}

-(NSTimer *)inactiveChatStateTimerForBuddyObjectID:(NSManagedObjectID *)
managedBuddyObjectID
{
   return [self buddyTimersForBuddyObjectID:managedBuddyObjectID].inactiveChatStateTimer;
    
}
-(NSTimer *)pausedChatStateTimerForBuddyObjectID:(NSManagedObjectID *)
managedBuddyObjectID
{
    return [self buddyTimersForBuddyObjectID:managedBuddyObjectID].pausedChatStateTimer;
}

-(void)restartPausedChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID
{
    OTRXMPPBudyTimers * timer = (OTRXMPPBudyTimers *)[buddyTimers objectForKey:managedBuddyObjectID];
    if(!timer)
    {
        timer = [[OTRXMPPBudyTimers alloc] init];
    }
    [timer.pausedChatStateTimer invalidate];
    timer.pausedChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStatePausedTimeout target:self selector:@selector(sendPausedChatState:) userInfo:managedBuddyObjectID repeats:NO];
    [buddyTimers setObject:timer forKey:managedBuddyObjectID];
}
-(void)restartInactiveChatStateTimerForBuddyObjectID:(NSManagedObjectID *)managedBuddyObjectID
{
    OTRXMPPBudyTimers * timer = (OTRXMPPBudyTimers *)[buddyTimers objectForKey:managedBuddyObjectID];
    if(!timer)
    {
        timer = [[OTRXMPPBudyTimers alloc] init];
    }
    [timer.inactiveChatStateTimer invalidate];
    timer.inactiveChatStateTimer = [NSTimer scheduledTimerWithTimeInterval:kOTRChatStateInactiveTimeout target:self selector:@selector(sendInactiveChatState:) userInfo:managedBuddyObjectID repeats:NO];
    [buddyTimers setObject:timer forKey:managedBuddyObjectID];
    
}
-(void)sendPausedChatState:(NSTimer *)timer
{
    NSManagedObjectID * managedBuddyObjectID= (NSManagedObjectID *)timer.userInfo;
    [timer invalidate];
    [self sendChatState:kOTRChatStatePaused withBuddyID:managedBuddyObjectID];
}
-(void)sendInactiveChatState:(NSTimer *)timer
{
    NSManagedObjectID * managedBuddyObjectID= (NSManagedObjectID *)timer.userInfo;
    [timer invalidate];
    [self sendChatState:kOTRChatStateInactive withBuddyID:managedBuddyObjectID];
    
}
-(BOOL)isConnected
{
    if (![xmppStream isDisconnected]) {
		return YES;
	}
    return NO;
}

@end
