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
#import "OTRBuddy.h"

//#define kSignoffTime 500

@implementation OTRBuddyListViewController
@synthesize buddyListTableView;
@synthesize chatViewControllers;
@synthesize chatListController;
@synthesize tabController;
@synthesize protocolManager;
@synthesize recentMessages;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
    
    
    chatViewControllers = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    buddyList = protocolManager.buddyList;
    
    recentMessages = [[NSMutableDictionary alloc] initWithCapacity:3];
}

-(void)viewWillAppear:(BOOL)animated
{
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*-(void)loggedInSuccessfully
{
    [loginController dismissModalViewControllerAnimated:YES];
}*/

-(void)buddyListUpdate
{
    buddyList = protocolManager.buddyList;
    [buddyList retain];

    [buddyListTableView reloadData];
    NSLog(@"blist update tableview");
    if(!buddyList)
        NSLog(@"blist is nil!");
    else
        NSLog(@"blist groups: %d", [buddyList count]);
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
         
         [recentMessages setObject:notification.userInfo forKey:userName];

         [alert show];
         [alert release];
     }
     
     if([chatViewControllers objectForKey:userName])
     {
         OTRChatViewController *chatController = [chatViewControllers objectForKey:userName];
         [chatController receiveMessage:decodedMessage];
     }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(buddyList)
        return [buddyList count];

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(buddyList)
    {
        NSArray *allKeys = [buddyList allKeys];
        NSString *currentKey = [allKeys objectAtIndex:section];
        
        NSDictionary *groupDictionary = [buddyList objectForKey:currentKey];
        
        return [groupDictionary objectForKey:@"group_name"];
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(buddyList)
    {
        NSArray *allKeys = [buddyList allKeys];
        NSString *currentKey = [allKeys objectAtIndex:section];
        
        NSDictionary *groupDictionary = [buddyList objectForKey:currentKey];
        NSDictionary *buddyDictionary = [groupDictionary objectForKey:@"group_data"];
        return [buddyDictionary count];
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
        NSArray *allKeys = [buddyList allKeys];
        NSString *currentKey = [allKeys objectAtIndex:indexPath.section];
        NSDictionary *groupDictionary = [buddyList objectForKey:currentKey];
        NSDictionary *buddyDictionary = [groupDictionary objectForKey:@"group_data"];
        NSArray *buddyKeys = [buddyDictionary allKeys];
        NSString *currentBuddyKey = [buddyKeys objectAtIndex:indexPath.row];
        
        OTRBuddy *buddyData = [buddyDictionary objectForKey:currentBuddyKey];
        
        NSString *buddyUsername = buddyData.name;
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
    NSArray *allKeys = [buddyList allKeys];
    NSString *currentKey = [allKeys objectAtIndex:indexPath.section];
    NSDictionary *groupDictionary = [buddyList objectForKey:currentKey];
    NSDictionary *buddyDictionary = [groupDictionary objectForKey:@"group_data"];
    NSArray *buddyKeys = [buddyDictionary allKeys];
    NSString *currentBuddyKey = [buddyKeys objectAtIndex:indexPath.row];
    
    OTRBuddy *buddyData = [buddyDictionary objectForKey:currentBuddyKey];
    
    NSString *buddyUsername = buddyData.name;
    NSString *buddyProtocol = buddyData.protocol;
    
    [self enterConversation:buddyUsername withProtocol:buddyProtocol];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)enterConversation:(NSString*)buddyName withProtocol:(NSString *)protocol
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
        NSDictionary *messageInfo = [recentMessages objectForKey:buddyName];
        if(messageInfo)
        {
            chatController.protocol = [messageInfo objectForKey:@"protocol"];
            chatController.accountName = [messageInfo objectForKey:@"recipient"];
        }
        else
        {
            chatController.protocol = protocol;
            chatController.accountName = [protocolManager accountNameForProtocol:protocol];
        }
        chatController.buddyListController = self;
        [chatViewControllers setObject:chatController forKey:buddyName];
    }
    
    if(tabController.selectedIndex == 0)
    {
        NSArray *controllerArray = [NSArray arrayWithObjects:self, chatController, nil];
        [self.navigationController setViewControllers:controllerArray animated:YES];
    }
    else
    {
        UIViewController *selected = chatListController;
        NSArray *controllerArray = [NSArray arrayWithObjects:selected, chatController, nil];
        [chatListController.navigationController setViewControllers:controllerArray animated:YES];
    }
    
    [recentMessages removeObjectForKey:buddyName];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1)
    {
        if(buttonIndex == 1) // Reply
        {
            if(alertView.title)
                [self enterConversation:alertView.title withProtocol:nil];
        }
        else // Ignore
        {
            [recentMessages removeObjectForKey:alertView.title];
        }
    }
}

@end
