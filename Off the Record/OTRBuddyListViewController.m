//
//  OTRBuddyListViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
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

#import "OTRBuddyListViewController.h"
#import "OTRChatViewController.h"
#import "OTRLoginViewController.h"
#import "OTRXMPPManager.h"
#import "OTRBuddy.h"
#import "OTRBuddyList.h"
#import "Strings.h"
#import "OTRConstants.h"
#import "OTRAppDelegate.h"
#import "OTRSettingsViewController.h"

//#define kSignoffTime 500

#define RECENTS_SECTION_INDEX 0
#define BUDDIES_SECTION_INDEX 1

@interface OTRBuddyListViewController(Private)
- (void) selectActiveConversation;
- (void) refreshActiveConversations;
- (void) removeConversationsForAccount:(OTRAccount *)account;
- (void) deleteBuddy:(OTRBuddy*)buddy;
@end

@implementation OTRBuddyListViewController
@synthesize buddyListTableView;
@synthesize chatViewController;
@synthesize protocolManager;
@synthesize activeConversations;
@synthesize buddyDictionary;
@synthesize sortedBuddies;
@synthesize selectedBuddy;

- (void) dealloc {
    self.protocolManager = nil;
    self.buddyListTableView = nil;
    self.chatViewController = nil;
    self.protocolManager = nil;
    self.activeConversations = nil;
    self.buddyDictionary = nil;
    self.sortedBuddies = nil;
    self.selectedBuddy = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        self.title = BUDDY_LIST_STRING;
        self.protocolManager = [OTRProtocolManager sharedInstance];
        self.buddyDictionary = [[NSMutableDictionary alloc] init];

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

- (void) loadView {
    [super loadView];
    self.buddyListTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    buddyListTableView.dataSource = self;
    buddyListTableView.delegate = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showSettingsView:)];
    [self.view addSubview:buddyListTableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(buddyListUpdate)
     name:kOTRBuddyListUpdate
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(messageReceived:)
     name:kOTRMessageReceived
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoggedOff:)
     name:kOTRProtocolLogout
     object:nil ];

    
    // uncomment to see a LOT of console output
	// [Debug setDebuggingEnabled:YES];
	NSLog(@"LibOrange (v: %@): -beginTest\n", @lib_orange_version_string);
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self buddyListUpdate];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kOTRBuddyListUpdate
     object:self];
    
    buddyListTableView.frame = self.view.bounds;
    buddyListTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //[self showEULAWarning];
}

- (void) showSettingsView:(id)sender {
    [self.navigationController pushViewController:[OTR_APP_DELEGATE settingsViewController] animated:YES];
}

- (void) showEULAWarning {
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:kOTRSettingUserAgreedToEULA] boolValue]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:SECURITY_WARNING_STRING message:[NSString stringWithFormat:@"%@\n\n%@",EULA_WARNING_STRING,EULA_BSD_STRING] delegate:self cancelButtonTitle:DISAGREE_STRING otherButtonTitles:AGREE_STRING,nil];
        alert.tag = 123;
        [alert show];
    }
    */
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.buddyListTableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

/*-(void)loggedInSuccessfully
{
    [loginController dismissModalViewControllerAnimated:YES];
}*/

-(void)buddyListUpdate
{
    NSLog(@"blist update tableview");
    if(!protocolManager.buddyList)
    {
        NSLog(@"blist is nil!");
        return;
    }
        
    sortedBuddies = [OTRBuddyList sortBuddies:protocolManager.buddyList.allBuddies];
    
    [buddyListTableView reloadData];
    [self selectActiveConversation];
}

-(void)messageReceived:(NSNotification*)notification;
{
    OTRMessage *message = [notification.userInfo objectForKey:@"message"];
    OTRBuddy *buddy = message.buddy;
    if (!message.message || [message.message isEqualToString:@""]) {
        return;
    }
    
    BOOL chatViewIsVisible = chatViewController.isViewLoaded && chatViewController.view.window;

    if ((chatViewController.buddy != buddy || !chatViewIsVisible) && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:buddy.displayName message:buddy.lastMessage delegate:self cancelButtonTitle:IGNORE_STRING otherButtonTitles:REPLY_STRING, nil];
        NSUInteger tag = [buddy hash];
        alert.tag = tag;
        [buddyDictionary setObject:buddy forKey:[NSNumber numberWithInt:tag]];
        [alert show];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == RECENTS_SECTION_INDEX) {
        return RECENT_STRING;
    } else if (section == BUDDIES_SECTION_INDEX) {
        return BUDDY_LIST_STRING;
    }
    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    if (sectionIndex == RECENTS_SECTION_INDEX) {
        return [self.activeConversations count];
    } else if (sectionIndex == BUDDIES_SECTION_INDEX) {
        return [protocolManager.buddyList count];
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
    OTRBuddy *buddy = nil;
    
    if (indexPath.section == RECENTS_SECTION_INDEX) {
        buddy = [activeConversations objectAtIndex:indexPath.row];
    } else if (indexPath.section == BUDDIES_SECTION_INDEX) {
        buddy = [sortedBuddies objectAtIndex:indexPath.row];
    }
            
    NSString *buddyUsername = buddy.displayName;
    OTRBuddyStatus buddyStatus = buddy.status;
    
    cell.textLabel.text = buddyUsername;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    
    switch(buddyStatus)
    {
        case kOTRBuddyStatusOffline:
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.detailTextLabel.text = OFFLINE_STRING;
            cell.imageView.image = [UIImage imageNamed:@"offline.png"];
            break;
        case kOTRBuddyStatusAway:
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.detailTextLabel.text = AWAY_STRING;
            cell.imageView.image = [UIImage imageNamed:@"away.png"];
            break;
        case kOTRBuddyStatusAvailable:
            cell.textLabel.textColor = [UIColor darkTextColor];
            cell.detailTextLabel.text = AVAILABLE_STRING;
            cell.imageView.image = [UIImage imageNamed:@"available.png"];
            break;
        default:
            cell.textLabel.textColor = [UIColor lightGrayColor];
            cell.detailTextLabel.text = OFFLINE_STRING;
            cell.imageView.image = [UIImage imageNamed:@"offline.png"];
    }
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == RECENTS_SECTION_INDEX) {
        return UITableViewCellEditingStyleDelete;
    } else if (indexPath.section == BUDDIES_SECTION_INDEX) {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == RECENTS_SECTION_INDEX) {
        OTRBuddy *buddy = [activeConversations objectAtIndex:indexPath.row];
        [self enterConversationWithBuddy:buddy];
    } else if (indexPath.section == BUDDIES_SECTION_INDEX) {
        if(sortedBuddies)
        {
            OTRBuddy *buddyData = [sortedBuddies objectAtIndex:indexPath.row];
            [self enterConversationWithBuddy:buddyData];
        }
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

-(void) protocolLoggedOff:(NSNotification *) notification
{
    id <OTRProtocol> protocol = notification.object;
    [self removeConversationsForAccount:protocol.account];
}

-(void) removeConversationsForAccount:(OTRAccount *)account {
    if ([OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyDeleteOnDisconnect]) {
        NSArray *iterableConversations = [activeConversations copy];
        
        for (OTRBuddy *buddy in iterableConversations) {
            if ([buddy.protocol.account.uniqueIdentifier isEqualToString:account.uniqueIdentifier]) {
                [[[[OTRProtocolManager sharedInstance] buddyList] activeConversations] removeObject:buddy];
            }
        }
        
        [self refreshActiveConversations];
    }
}

- (void) refreshActiveConversations {
    self.activeConversations = [NSMutableArray arrayWithArray:[[OTRProtocolManager sharedInstance].buddyList.activeConversations allObjects]];
    
    [buddyListTableView reloadData];
    
    [self selectActiveConversation];
}

- (void) selectActiveConversation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return;
    }
    if ([activeConversations containsObject:selectedBuddy]) {
        int indexOfSelectedBuddy = [activeConversations indexOfObject:selectedBuddy];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfSelectedBuddy inSection:RECENTS_SECTION_INDEX];
        [self.buddyListTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}


- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RECENTS_SECTION_INDEX && editingStyle == UITableViewCellEditingStyleDelete) {
        OTRBuddy *buddy = [activeConversations objectAtIndex:indexPath.row];
        [self deleteBuddy:buddy];
        [self refreshActiveConversations];
    }
}

- (void) deleteBuddy:(OTRBuddy*)buddy {
    buddy.chatHistory = [NSMutableString string];
    buddy.lastMessage = @"";
    [[[[OTRProtocolManager sharedInstance] buddyList] activeConversations] removeObject:buddy];
}

-(void)enterConversationWithBuddy:(OTRBuddy*)buddy 
{
    if(!buddy) {
        return;
    }
    self.selectedBuddy = buddy;
    [protocolManager.buddyList.activeConversations addObject:buddy];
    chatViewController.buddy = buddy;
    
    BOOL chatViewIsVisible = chatViewController.isViewLoaded && chatViewController.view.window;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && !chatViewIsVisible && self.navigationController.visibleViewController != chatViewController) {
        [self.navigationController setViewControllers:[NSArray arrayWithObjects:self, chatViewController, nil] animated:YES];
    }
    [self refreshActiveConversations];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    OTRBuddy *buddy = [buddyDictionary objectForKey:[NSNumber numberWithInt: alertView.tag]];
    //[buddyDictionary removeObjectForKey:[NSNumber numberWithInt:alertView.tag]];
    if(buttonIndex == 1) // Reply
    {
        [self enterConversationWithBuddy:buddy];
    }
}

@end
