//
//  OTRChatListViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//

#import "OTRChatListViewController.h"
#import "OTRChatViewController.h"
#import "Strings.h"
#import "OTRProtocol.h"
#import "OTRConstants.h"

@implementation OTRChatListViewController

@synthesize buddyController;
@synthesize chatListTableView;
@synthesize activeConversations;

- (void) dealloc {
    self.activeConversations = nil;
    self.chatListTableView = nil;
    self.buddyController = nil;
}

- (id)init {
    if (self = [super init]) {
        self.title = CONVERSATIONS_STRING;
        self.tabBarItem.image = [UIImage imageNamed:@"08-chat.png"];
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
    self.chatListTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    chatListTableView.dataSource = self;
    chatListTableView.delegate = self;
    [self.view addSubview:chatListTableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(protocolLoggedOff:)
     name:kOTRProtocolLogout
     object:nil ];
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


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    chatListTableView.frame = self.view.bounds;
    chatListTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    [self refreshActiveConversations];
}

- (void) refreshActiveConversations {
    self.activeConversations = [NSMutableArray arrayWithArray:[[OTRProtocolManager sharedInstance].buddyList.activeConversations allObjects]];
    
    [chatListTableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.chatListTableView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kOTRProtocolLogout object:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[[OTRProtocolManager sharedInstance] buddyList] activeConversations] count];
}

- (void) deleteBuddy:(OTRBuddy*)buddy {
    buddy.chatHistory = [NSMutableString string];
    buddy.lastMessage = @"";
    [[[[OTRProtocolManager sharedInstance] buddyList] activeConversations] removeObject:buddy];
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OTRBuddy *buddy = [activeConversations objectAtIndex:indexPath.row];
        [self deleteBuddy:buddy];
        [self refreshActiveConversations];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}
    
    OTRBuddy *buddy = [activeConversations objectAtIndex:indexPath.row];
    cell.textLabel.text = buddy.displayName;
    cell.detailTextLabel.text = buddy.lastMessage;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *convoList = [[[[OTRProtocolManager sharedInstance] buddyList] activeConversations] allObjects];
    OTRBuddy *buddy = [convoList objectAtIndex:indexPath.row];
    OTRChatViewController *chatView = buddyController.chatViewController;
    chatView.buddy = buddy;
    
    [self.navigationController pushViewController:chatView animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
