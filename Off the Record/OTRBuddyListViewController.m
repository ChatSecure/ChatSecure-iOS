//
//  OTRBuddyListViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTRBuddyListViewController.h"
#import "OTRChatViewController.h"
#import "OTRLoginViewController.h"
#import "message.h"
#import "privkey.h"

//#define kSignoffTime 500

@implementation OTRBuddyListViewController
@synthesize buddyListTableView;
@synthesize login;
@synthesize accountName;
@synthesize chatViewControllers;
@synthesize messageCodec;

- (void)blockingCheck {
	static NSDate * lastTime = nil;
	if (!lastTime) {
		lastTime = [[NSDate date] retain];
	} else {
		NSDate * newTime = [NSDate date];
		NSTimeInterval ti = [newTime timeIntervalSinceDate:lastTime];
		if (ti > 0.2) {
			NSLog(@"Main thread blocked for %d milliseconds.", (int)round(ti * 1000.0));
		}
		[lastTime release];
		lastTime = [newTime retain];
	}
	[self performSelector:@selector(blockingCheck) withObject:nil afterDelay:0.05];
}

- (void)checkThreading {
	if ([NSThread currentThread] != mainThread) {
		NSLog(@"warning: NOT RUNNING ON MAIN THREAD!");
	}
}


#pragma mark Login Delegate

- (void)aimLogin:(AIMLogin *)theLogin failedWithError:(NSError *)error {
	[self checkThreading];
    
    NSLog(@"login error: %@",[error description]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:@"AIM login failed. Please check your username and password and try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
    
	[login release];
}

- (void)aimLogin:(AIMLogin *)theLogin openedSession:(AIMSessionManager *)session {
	[self checkThreading];
	[session setDelegate:self];
	[login release];
	login = nil;
	theSession = [session retain];
	
	/* Set handler delegates */
	session.feedbagHandler.delegate = self;
	session.messageHandler.delegate = self;
	session.statusHandler.delegate = self;
	session.rateHandler.delegate = self;
	session.rendezvousHandler.delegate = self;
	
	[session configureBuddyArt];
	AIMCapability * fileTransfers = [[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer];
	AIMCapability * getFiles = [[AIMCapability alloc] initWithType:AIMCapabilityGetFiles];
	NSArray * caps = [NSArray arrayWithObjects:[fileTransfers autorelease], [getFiles autorelease], nil];
	AIMBuddyStatus * newStatus = [[AIMBuddyStatus alloc] initWithMessage:@"Available" type:AIMBuddyStatusAvailable timeIdle:0 caps:caps];
	[session.statusHandler updateStatus:newStatus];
	[newStatus release];
	
	NSLog(@"Got session: %@", session);
	NSLog(@"Our status: %@", session.statusHandler.userStatus);
	//NSLog(@"Disconnecting in %d seconds ...", kSignoffTime);
	//[[session session] performSelector:@selector(closeConnection) withObject:nil afterDelay:kSignoffTime];
	
	// uncomment to test rate limit detection.
	// [self sendBogus];
    messageCodec = [[OTRCodec alloc] initWithAccountName:accountName];
    [loginController dismissModalViewControllerAnimated:YES];
}

#pragma mark Session Delegate

- (void)aimSessionManagerSignedOff:(AIMSessionManager *)sender {
	[self checkThreading];
	[theSession autorelease];
	theSession = nil;
	NSLog(@"Session signed off");
}

#pragma mark Buddy List Methods

- (void)aimFeedbagHandlerGotBuddyList:(AIMFeedbagHandler *)feedbagHandler {
	[self checkThreading];
	NSLog(@"%@ got the buddy list.", feedbagHandler);
	//NSLog(@"Blist: %@", );
    
    buddyList = [[theSession.session buddyList] retain];
    
    [buddyListTableView reloadData];
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyAdded:(AIMBlistBuddy *)newBuddy {
	[self checkThreading];
	NSLog(@"Buddy added: %@", newBuddy);
    
    [buddyListTableView reloadData];
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDeleted:(AIMBlistBuddy *)oldBuddy {
	[self checkThreading];
	NSLog(@"Buddy removed: %@", oldBuddy);
    
    [buddyListTableView reloadData];

}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupAdded:(AIMBlistGroup *)newGroup {
	[self checkThreading];
	NSLog(@"Group added: %@", [newGroup name]);
    
    [buddyListTableView reloadData];

}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupDeleted:(AIMBlistGroup *)oldGroup {
	[self checkThreading];
	NSLog(@"Group removed: %@", [oldGroup name]);
    
    [buddyListTableView reloadData];

}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupRenamed:(AIMBlistGroup *)theGroup {
	[self checkThreading];
	NSLog(@"Group renamed: %@", [theGroup name]);
	NSLog(@"Blist: %@", theSession.session.buddyList);
    
    [buddyListTableView reloadData];

}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDenied:(NSString *)username {
	NSLog(@"User blocked: %@", username);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyPermitted:(NSString *)username {
	NSLog(@"User permitted: %@", username);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUndenied:(NSString *)username {
	NSLog(@"User un-blocked: %@", username);
}
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyUnpermitted:(NSString *)username {
	NSLog(@"User un-permitted: %@", username);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender transactionFailed:(id<FeedbagTransaction>)transaction {
	[self checkThreading];
	NSLog(@"Transaction failed: %@", transaction);
}

#pragma mark Message Handler

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMessage:(AIMMessage *)message {
	[self checkThreading];
	
	NSString * msgTxt = [message plainTextMessage];
	
	NSString * autoresp = [message isAutoresponse] ? @" (Auto-Response)" : @"";
	NSLog(@"(%@) %@%@: %@", [NSDate date], [[message buddy] username], autoresp, [message plainTextMessage]);
    
    NSString *decodedMessage = [messageCodec decodeMessage:[message plainTextMessage] fromUser:message.buddy.username];
    
    if(decodedMessage)
    {
        if(![[self.navigationController visibleViewController].title isEqualToString:message.buddy.username])
        {

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message.buddy.username message:decodedMessage delegate:self cancelButtonTitle:@"Ignore" otherButtonTitles:@"Reply", nil];
            alert.tag = 1;
            [alert show];
            [alert release];
        }

        
        if([chatViewControllers objectForKey:message.buddy.username])
        {
            OTRChatViewController *chatController = [chatViewControllers objectForKey:message.buddy.username];
            [chatController receiveMessage:decodedMessage];
        }
    }
	
	NSArray * tokens = [CommandTokenizer tokensOfCommand:msgTxt];
	if ([tokens count] == 1) {
		if ([[tokens objectAtIndex:0] isEqual:@"blist"]) {
			NSString * desc = [[theSession.session buddyList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"takeicon"]) {
			NSData * iconData = [[[message buddy] buddyIcon] iconData];
			if (iconData) {
				[theSession.statusHandler updateUserIcon:iconData];
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Icon set requested."]];
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Err: Couldn't get your icon!"]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"bye"]) {
			[[theSession session] closeConnection];
		} else if ([[tokens objectAtIndex:0] isEqual:@"deny"]) {
			NSString * desc = [[[theSession.session buddyList] denyList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"permit"]) {
			NSString * desc = [[[theSession.session buddyList] permitList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"pdmode"]) {
			NSString * desc = PD_MODE_TOSTR([theSession.feedbagHandler currentPDMode:NULL]);
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"caps"]) {
			NSString * desc = [[[[message buddy] status] capabilities] description];
			if (desc) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:@"Err: Capabilities unavailable."]];
			}
		}
	} else if ([tokens count] == 2) {
		if ([[tokens objectAtIndex:0] isEqual:@"delbuddy"]) {
			NSString * msg = [self removeBuddy:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"addgroup"]) {
			NSString * msg = [self addGroup:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"delgroup"]) {
			NSString * msg = [self deleteGroup:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"echo"]) {
			NSString * msg = [tokens objectAtIndex:1];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
		} else if ([[tokens objectAtIndex:0] isEqual:@"sendfile"]) {
			NSString * messagestr = [tokens objectAtIndex:1];
			BOOL canTransfer = NO;
			for (AIMCapability * cap in message.buddy.status.capabilities) {
				if ([cap capabilityType] == AIMCapabilityFileTransfer) {
					canTransfer = YES;
				}
			}
			if (canTransfer) {
				NSString * tempPath = [NSTemporaryDirectory() stringByAppendingFormat:@"/%d%d.txt", arc4random(), time(NULL)];
				[messagestr writeToFile:tempPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
				if (![theSession.rendezvousHandler sendFile:tempPath toUser:message.buddy]) {
					[[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
					[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Err: sendfile failed." stringByAddingAOLRTFTags]]];
				} else {
					[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Sendfile started." stringByAddingAOLRTFTags]]];
				}
			} else {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[@"Err: you can't receive files." stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"deny"]) {
			NSString * msg = [self denyUser:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"undeny"]) {
			NSString * msg = [self undenyUser:[tokens objectAtIndex:1]];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	} else if ([tokens count] == 3) {
		if ([[tokens objectAtIndex:0] isEqual:@"addbuddy"]) {
			NSString * group = [tokens objectAtIndex:1];
			NSString * buddy = [tokens objectAtIndex:2];
			NSString * msg = [self addBuddy:buddy toGroup:group];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	}
}

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMissedCall:(AIMMissedCall *)missedCall {
	[self checkThreading];
	NSLog(@"Missed call from %@", [missedCall buddy]);
}

#pragma mark Status Handler

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status {
	[self checkThreading];
	NSLog(@"\"%@\"%s%@", theBuddy, ".status = ", status);
    
    [buddyListTableView reloadData];
}

- (void)aimStatusHandlerUserStatusUpdated:(AIMStatusHandler *)handler {
	[self checkThreading];
	NSLog(@"user.status = %@", [handler userStatus]);
    
    [buddyListTableView reloadData];
}

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyIconChanged:(AIMBlistBuddy *)theBuddy {
	[self checkThreading];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dirPath = [paths objectAtIndex:0];

	if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
		NSString * path = nil;
		AIMBuddyIconFormat fmt = [[theBuddy buddyIcon] iconDataFormat];
		switch (fmt) {
			case AIMBuddyIconBMPFormat:
				path = [dirPath stringByAppendingFormat:@"%@.bmp", [theBuddy username]];
				break;
			case AIMBuddyIconGIFFormat:
				path = [dirPath stringByAppendingFormat:@"%@.gif", [theBuddy username]];
				break;
			case AIMBuddyIconJPEGFormat:
				path = [dirPath stringByAppendingFormat:@"%@.jpg", [theBuddy username]];
				break;
			default:
				break;
		}
		if (path) {
			[[[theBuddy buddyIcon] iconData] writeToFile:path atomically:YES];
		}
	}
}

- (void)aimStatusHandler:(AIMStatusHandler *)handler setIconFailed:(AIMIconUploadErrorType)reason {
	NSLog(@"Failed to set our buddy icon.");
}

#pragma mark Rate Handlers

- (void)aimRateLimitHandler:(AIMRateLimitHandler *)handler gotRateAlert:(AIMRateNotificationInfo *)info {
	// use this to show the user that they should stop sending messages.
	NSLog(@"Rate alert");
}

#pragma mark File Transfers

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferRequested:(AIMReceivingFileTransfer *)ft {
	/*NSLog(@"Auto-accepting transfer: %@", ft);
	NSString * path = [NSString stringWithFormat:@"/var/tmp/%@", [ft remoteFileName]];
	[rvHandler acceptFileTransfer:ft saveToPath:path];
	NSLog(@"Save to path: %@", path);*/
    NSLog(@"File transfer disabled.");
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferCancelled:(AIMFileTransfer *)ft reason:(UInt16)reason {
	NSLog(@"File transfer cancelled: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferFailed:(AIMFileTransfer *)ft {
	NSLog(@"File transfer failed: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferStarted:(AIMFileTransfer *)ft {
	NSLog(@"File transfer started: %@", ft);
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferProgressChanged:(AIMFileTransfer *)ft {
	// cancel it a bit of the way through to test that cancelling works.
	// if ([ft progress] > 0.1) [rvHandler cancelFileTransfer:ft];
	// NSLog(@"%@ progress = %f", ft, [ft progress]);
}

- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferDone:(AIMFileTransfer *)ft {
	NSLog(@"File transfer done: %@", ft);
	if ([ft isKindOfClass:[AIMSendingFileTransfer class]]) {
		AIMSendingFileTransfer * send = (AIMSendingFileTransfer *)ft;
		[[NSFileManager defaultManager] removeItemAtPath:[send localFile] error:nil];
	}
}

#pragma mark Commands

- (NSString *)removeBuddy:(NSString *)username {
	AIMBlistBuddy * buddy = [theSession.session.buddyList buddyWithUsername:username];
	if (buddy && [buddy group]) {
		FTRemoveBuddy * remove = [[FTRemoveBuddy alloc] initWithBuddy:buddy];
		[theSession.feedbagHandler pushTransaction:remove];
		[remove release];
		return @"Remove (buddy) request sent.";
	} else {
		return @"Err: buddy not found.";
	}
}
- (NSString *)addBuddy:(NSString *)username toGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	AIMBlistBuddy * buddy = [group buddyWithUsername:username];
	if (buddy) {
		return @"Err: buddy exists.";
	}
	FTAddBuddy * addBudd = [[FTAddBuddy alloc] initWithUsername:username group:group];
	[theSession.feedbagHandler pushTransaction:addBudd];
	[addBudd release];
	return @"Add (buddy) request sent.";
}
- (NSString *)deleteGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	FTRemoveGroup * delGrp = [[FTRemoveGroup alloc] initWithGroup:group];
	[theSession.feedbagHandler pushTransaction:delGrp];
	[delGrp release];
	return @"Delete (group) request sent.";
}
- (NSString *)addGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (group) {
		return @"Err: group exists.";
	}
	FTAddGroup * addGrp = [[FTAddGroup alloc] initWithName:groupName];
	[theSession.feedbagHandler pushTransaction:addGrp];
	[addGrp release];
	return @"Add (group) request sent.";
}
- (NSString *)denyUser:(NSString *)username {
	NSString * msg = @"Deny add sent!";
	if ([theSession.feedbagHandler currentPDMode:NULL] != PD_MODE_DENY_SOME) {
		FTSetPDMode * pdMode = [[FTSetPDMode alloc] initWithPDMode:PD_MODE_DENY_SOME pdFlags:PD_FLAGS_APPLIES_IM];
		[theSession.feedbagHandler pushTransaction:pdMode];
		[pdMode release];
		msg = @"Set PD_MODE and sent add deny";
	}
	FTAddDeny * deny = [[FTAddDeny alloc] initWithUsername:username];
	[theSession.feedbagHandler pushTransaction:deny];
	[deny release];
	return msg;
}
- (NSString *)undenyUser:(NSString *)username {
	NSString * msg = @"Deny delete sent!";
	if ([theSession.feedbagHandler currentPDMode:NULL] != PD_MODE_DENY_SOME) {
		msg = @"Warning: Deny delete sent but PD_MODE isn't DENY_SOME";
	}
	FTDelDeny * delDeny = [[FTDelDeny alloc] initWithUsername:username];
	[theSession.feedbagHandler pushTransaction:delDeny];
	[delDeny release];
	return msg;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // uncomment to see a LOT of console output
	// [Debug setDebuggingEnabled:YES];
	NSLog(@"LibOrange (v: %@): -beginTest\n", @lib_orange_version_string);
	mainThread = [NSThread currentThread];


    [self blockingCheck];

    
    self.title = @"Buddy List";
    
    chatViewControllers = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    OTRLoginViewController *loginViewController = [[OTRLoginViewController alloc] init];
    loginViewController.buddyController = self;
    [self presentModalViewController:loginViewController animated:YES];
    loginController = loginViewController;
    
    
    // initialize OTR
    OTRL_INIT;
    s_OTR_userState = otrl_userstate_create();
    //otrl_privkey_read(OTR_userState,"privkeyfilename");
    //otrl_privkey_read_fingerprints(OTR_userState, "fingerprintfilename", NULL, NULL);
    
    
}

- (void)viewDidUnload
{
    [self setBuddyListTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(buddyList)
        return [buddyList.groups count];

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(buddyList)
    {
        AIMBlistGroup *group = [buddyList.groups objectAtIndex:section];
        return group.name;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(buddyList)
    {
        AIMBlistGroup *group = [buddyList.groups objectAtIndex:section];
        return [group.buddies count];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}
	
    if(buddyList)
    {
        AIMBlistGroup *group = [[buddyList.groups objectAtIndex:indexPath.section] retain];
        AIMBlistBuddy *buddy = [group.buddies objectAtIndex:indexPath.row];
        cell.textLabel.text =  buddy.username;
        
        //cell.imageView.image = [UIImage imageWithData:buddy.buddyIcon.iconData];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        if(buddy.status.statusType == AIMBuddyStatusOffline)
        {
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.detailTextLabel.text = @"Offline";
        }
        else if(buddy.status.statusType == AIMBuddyStatusAway)
        {
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.detailTextLabel.text = @"Away";
        }
        else if(buddy.status.statusType == AIMBuddyStatusAvailable)
        {
            cell.textLabel.textColor = [UIColor darkTextColor];
            cell.detailTextLabel.text = @"Available";

        }
        if(![buddy.status.statusMessage isEqualToString:@""])
            cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@": %@", buddy.status.statusMessage];

    }
    
    
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *buddyName = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    [self enterConversation:buddyName];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)enterConversation:(NSString*)buddyName
{
    OTRChatViewController *chatController;
    if([chatViewControllers objectForKey:buddyName])
    {
        chatController = [chatViewControllers objectForKey:buddyName];
    }
    else
    {
        chatController = [[OTRChatViewController alloc] init];
        chatController.title = buddyName;
        chatController.buddyListController = self;
        [chatViewControllers setObject:chatController forKey:buddyName];
    }
    
    NSArray *controllerArray = [NSArray arrayWithObjects:self, chatController, nil];
    [self.navigationController setViewControllers:controllerArray animated:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1)
    {
        if(buttonIndex == 1) // Reply
        {
            if(alertView.title)
                [self enterConversation:alertView.title];
        }
    }
}

+(OtrlUserState) OTR_userState
{
    return s_OTR_userState;
}

+(AIMSessionManager*) AIMSession
{
    return theSession;
}



@end
