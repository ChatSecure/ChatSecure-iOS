//
//  OTRBuddyListViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyListViewController.h"
#import "OTRChatViewController.h"
#import "OTRLoginViewController.h"
#import "OTRXMPPManager.h"
#import "OTRBuddy.h"
#import "OTRBuddyList.h"

//#define kSignoffTime 500

@implementation OTRBuddyListViewController
@synthesize buddyListTableView;
@synthesize chatViewController;
@synthesize chatListController;
@synthesize tabController;
@synthesize protocolManager;


- (id)init {
    if (self = [super init]) {
        self.title = @"Buddy List";
        self.tabBarItem.image = [UIImage imageNamed:@"112-group.png"];
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
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(buddyListUpdate)
     name:@"BuddyListUpdateNotification"
     object:nil ];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(messageReceived:)
     name:@"MessageReceivedNotification"
     object:nil ];

    
    // uncomment to see a LOT of console output
	// [Debug setDebuggingEnabled:YES];
	NSLog(@"LibOrange (v: %@): -beginTest\n", @lib_orange_version_string);
    protocolManager = [OTRProtocolManager sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated
{
    //[self buddyListUpdate];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"BuddyListUpdateNotification"
     object:self];
    
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
        
    sortedBuddies = [OTRBuddyList sortBuddies:[protocolManager.buddyList allBuddies]];
    
    [buddyListTableView reloadData];
}

-(void)messageReceived:(NSNotification*)notification;
{
    OTRMessage *message = [notification.userInfo objectForKey:@"message"];
    NSString *userName = message.sender;
    NSString *decodedMessage = message.message;
    
    
    if(![[self.navigationController visibleViewController].title isEqualToString:userName] && ![[chatListController.navigationController visibleViewController].title isEqualToString:userName])
     {
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:userName message:decodedMessage delegate:self cancelButtonTitle:@"Ignore" otherButtonTitles:@"Reply", nil];
         alert.tag = 1;
         

         [alert show];
     }
    
    OTRBuddy *buddy = [protocolManager.buddyList getBuddyByName:userName];
    [buddy receiveMessage:decodedMessage];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    if(protocolManager.buddyList)
    {
        NSLog(@"Buddy list count: %d",[protocolManager.buddyList count]);
        return [protocolManager.buddyList count];
        
        
       /* NSArray *sections = [protocolManager frcSections];
        
        if (sectionIndex < [sections count])
        {
            id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
            return sectionInfo.numberOfObjects;
        }
        
        return 0;*/
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
	
    if(sortedBuddies)
    {
        OTRBuddy *buddyData = [sortedBuddies objectAtIndex:indexPath.row];
        
        NSString *buddyUsername = buddyData.displayName;
        OTRBuddyStatus buddyStatus = buddyData.status;
        
        cell.textLabel.text = buddyUsername;
                
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        switch(buddyStatus)
        {
            case kOTRBuddyStatusOffline:
                cell.textLabel.textColor = [UIColor lightGrayColor];
                cell.detailTextLabel.text = @"Offline";
                cell.imageView.image = [UIImage imageNamed:@"offline.png"];
                break;
            case kOTRBuddyStatusAway:
                cell.textLabel.textColor = [UIColor darkGrayColor];
                cell.detailTextLabel.text = @"Away";
                cell.imageView.image = [UIImage imageNamed:@"away.png"];
                break;
            default:
                cell.textLabel.textColor = [UIColor darkTextColor];
                cell.detailTextLabel.text = @"Available";
                cell.imageView.image = [UIImage imageNamed:@"available.png"];
                break;
        }
    }
    
    
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(sortedBuddies)
    {
        OTRBuddy *buddyData = [sortedBuddies objectAtIndex:indexPath.row];
        [self enterConversationWithBuddy:buddyData];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


-(void)enterConversationWithBuddy:(OTRBuddy*)buddy 
{
    [protocolManager.buddyList.activeConversations addObject:buddy];
    chatViewController.buddy = buddy;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.tabBarController.selectedIndex = 1;
        [chatListController.navigationController pushViewController:chatViewController animated:NO];
    } 
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1)
    {
        NSString * buddyName = alertView.title;
        OTRBuddy *buddy = [protocolManager.buddyList getBuddyByName:buddyName];
        if(buttonIndex == 1) // Reply
        {
            if(alertView.title)
            {
                [self enterConversationWithBuddy:buddy];
            }
        }   
        else // Ignore
        {
        }
    }
}

@end
