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
#import "Strings.h"
#import "OTRConstants.h"


//#define kSignoffTime 500

@implementation OTRBuddyListViewController
@synthesize buddyListTableView;
@synthesize chatViewController;
@synthesize chatListController;
@synthesize tabController;
@synthesize protocolManager;

- (void) dealloc {
    self.protocolManager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    if (self = [super init]) {
        self.title = BUDDY_LIST_STRING;
        self.tabBarItem.image = [UIImage imageNamed:@"112-group.png"];
        self.protocolManager = [OTRProtocolManager sharedInstance];
        buddyDictionary = [[NSMutableDictionary alloc] init];

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
    [self showEULAWarning];
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
}

-(void)messageReceived:(NSNotification*)notification;
{
    OTRMessage *message = [notification.userInfo objectForKey:@"message"];
    NSString *decodedMessage = message.message;
    OTRBuddy *buddy = message.buddy;
    [buddy receiveMessage:decodedMessage];
    
    UIViewController * currentViewController;
    
    NSString * currentTitle;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        currentViewController = self.tabBarController.selectedViewController;
        if ([currentViewController isKindOfClass:[UISplitViewController class]]) {
            currentTitle = [((UISplitViewController *)currentViewController).viewControllers objectAtIndex:1];
        }
        
    }
    else {
        currentViewController = chatListController.navigationController.topViewController;
    }
    
    if(![currentViewController isKindOfClass:[OTRChatViewController class]])
    {
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:buddy.displayName message:buddy.lastMessage delegate:self cancelButtonTitle:IGNORE_STRING otherButtonTitles:REPLY_STRING, nil];
        NSUInteger tag = [buddy hash];
        alert.tag = tag;
        [buddyDictionary setObject:buddy forKey:[NSNumber numberWithInt:tag]];
        [alert show];
        
    }
    else {
        if (![((OTRChatViewController *)currentViewController).buddy.protocol.account isEqual:buddy.protocol.account] && ![buddy.lastMessage isEqualToString:@""] && [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:buddy.displayName message:buddy.lastMessage delegate:self cancelButtonTitle:IGNORE_STRING otherButtonTitles:REPLY_STRING, nil];
            NSUInteger tag = [buddy hash];
            alert.tag = tag;
            [buddyDictionary setObject:buddy forKey:[NSNumber numberWithInt:tag]];
            [alert show];
        }
    }
    
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
                cell.detailTextLabel.text = OFFLINE_STRING;
                cell.imageView.image = [UIImage imageNamed:@"offline.png"];
                break;
            case kOTRBuddyStatusAway:
                cell.textLabel.textColor = [UIColor darkGrayColor];
                cell.detailTextLabel.text = AWAY_STRING;
                cell.imageView.image = [UIImage imageNamed:@"away.png"];
                break;
            default:
                cell.textLabel.textColor = [UIColor darkTextColor];
                cell.detailTextLabel.text = AVAILABLE_STRING;
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


-(void)enterConversationWithBuddy:(OTRBuddy*)buddy 
{
    if(buddy) {
        [protocolManager.buddyList.activeConversations addObject:buddy];
        chatViewController.buddy = buddy;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.tabBarController.selectedIndex = 1;
            chatListController.navigationController.viewControllers = [NSArray arrayWithObjects:chatListController, chatViewController, nil];
            //[chatListController.navigationController pushViewController:chatViewController animated:YES];
        } else {
            self.tabBarController.selectedIndex = 0;
        }
    }

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    
    OTRBuddy *buddy = [buddyDictionary objectForKey:[NSNumber numberWithInt: alertView.tag]];
    //[buddyDictionary removeObjectForKey:[NSNumber numberWithInt:alertView.tag]];
    if(buttonIndex == 1) // Reply
    {
        [self enterConversationWithBuddy:buddy];
    }   
    else // Ignore
    {
    }
    /* Unsused for
    else if (alertView.tag == 123)
    {
        if (buttonIndex == alertView.cancelButtonIndex) 
        {
            [self showEULAWarning];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://en.wikipedia.org/wiki/Off-the-Record_Messaging"]];
        }
        else
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[NSNumber numberWithBool:YES] forKey:kOTRSettingUserAgreedToEULA];
            [defaults synchronize];
        }
        NSLog(@"buttonIndex: %d", buttonIndex);
    }
     */
}

@end
