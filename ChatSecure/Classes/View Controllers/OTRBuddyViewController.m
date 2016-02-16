//
//  OTRBuddyViewController.m
//  Off the Record
//
//  Created by David on 3/6/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRInLineTextEditTableViewCell.h"
#import "OTRStrings.h"
#import "OTRProtocolManager.h"
#import "OTRConstants.h"
#import "OTRUtilities.h"
#import "OTRXMPPManager.h"
#import "UIActivityViewController+ChatSecure.h"
#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRDatabaseManager.h"
#import "OTRUtilities.h"
#import "OTRLanguageManager.h"

@interface OTRBuddyViewController ()

@property (nonatomic, strong) OTRAccount *account;

@end

@implementation OTRBuddyViewController



-(id)initWithBuddyID:(NSString *)buddyID
{
    if(self = [self init])
    {
        [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            self.buddy = [OTRBuddy fetchObjectWithUniqueID:buddyID transaction:transaction];
            self.account = [self.buddy accountWithTransaction:transaction];
            isXMPPAccount = [[self.account protocolClass] isSubclassOfClass:[OTRXMPPManager class]];
        }];
        
        self.title = BUDDY_INFO_STRING;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    
    UITableView * tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:tableView];
    
    displayNameTextField = [[UITextField alloc]init];
    displayNameTextField.placeholder = OPTIONAL_STRING;
    displayNameTextField.font = [UIFont systemFontOfSize:15];
    
    displayNameTextField.delegate = self;
    
    if ([self.buddy.displayName length] && ![self.buddy.displayName isEqualToString:self.buddy.username]) {
        displayNameTextField.text = self.buddy.displayName;
    }
    
    removeBuddyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [removeBuddyButton setTitle:REMOVE_STRING forState:UIControlStateNormal];
    [removeBuddyButton addTarget:self action:@selector(removeBuddyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    blockBuddyButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [blockBuddyButton setTitle:BLOCK_STRING forState:UIControlStateNormal];
    
    if (!isXMPPAccount) {
        [blockBuddyButton setTitle:BLOCK_AND_REMOVE_STRING forState:UIControlStateNormal];
    }
    
    /*FIXMEif (!self.account.isConnected) {
        removeBuddyButton.enabled = NO;
        blockBuddyButton.enabled = NO;
        displayNameTextField.enabled = NO;
    }*/
    
    
    [blockBuddyButton addTarget:self action:@selector(blockBuddyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    removeBuddyButton.autoresizingMask  = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin  ;
    blockBuddyButton.autoresizingMask =UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin ;
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ((section == 1 && isXMPPAccount) || section == 2) {
        return 2;
    }
    return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 80.0f;
    }
    return 44.0f;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"cell";
    static NSString * cellIdentifierText = @"cellText";
    static NSString * cellIdentifierLabel = @"cellLabel";
    static NSString * cellIdentifierGroups = @"cellgroups";
    static NSString * cellIdentifierButtons = @"cellgroups";
    UITableViewCell * cell = nil;
    
    
    if (indexPath.section == 0) {
        // Image and Status
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        [self setupPhotoCell:cell];
    }
    else if (indexPath.section == 1 && indexPath.row == 0)
    {
        //Account Name
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierLabel];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifierLabel];
            cell.textLabel.text = EMAIL_STRING;
            cell.detailTextLabel.text = self.buddy.username;
        }
        
    }
    else if(indexPath.section == 1 && indexPath.row == 1){
        //Display Name
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierText];
        if (!cell) {
            cell =[[OTRInLineTextEditTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellIdentifierText];
        }
        cell.textLabel.text = NAME_STRING;
        [cell layoutIfNeeded];
        ((OTRInLineTextEditTableViewCell *)cell).textField = displayNameTextField;
    }
    else if(indexPath.section == 2)
    {
        //Groups
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierGroups];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifierGroups];
        }
        
        if (indexPath.row == 0) {
            cell.textLabel.text = ACCOUNT_STRING;
            cell.detailTextLabel.text = self.account.username;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    else if(indexPath.section == 3 && indexPath.row == 0)
    {
        //remove and block
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierButtons];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            [self setupButtonsCell:cell];
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2 && indexPath.row == 0) {
        //go to edit groups view
    }
}

-(void)setupButtonsCell:(UITableViewCell *)cell
{
    cell.backgroundView = cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    CGSize cellSize = cell.contentView.frame.size;
    CGFloat buttonWidth = 150;
    
    removeBuddyButton.frame = CGRectMake(0, 0, buttonWidth, cellSize.height);
    blockBuddyButton.frame = CGRectMake(cellSize.width-buttonWidth, 0, buttonWidth, cellSize.height);
    
    [cell.contentView addSubview:removeBuddyButton];
    [cell.contentView addSubview:blockBuddyButton];
    
    
}

-(void)setupPhotoCell:(UITableViewCell *)cell
{
    cell.backgroundView = cell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    UIImageView * buddyImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0, 5.0, 70.0, 70.0)];
    buddyImageView.backgroundColor = [UIColor lightGrayColor];
    
    /*FIXMEif (self.buddy.photo) {
        //FIXMEbuddyImageView.image = self.buddy.photo;
    }
    else
    {
        buddyImageView.image = [UIImage imageNamed:@"person"];
    }
    [buddyImageView.layer setCornerRadius:10.0];
    buddyImageView.layer.masksToBounds = YES;
    
    [cell.contentView addSubview:buddyImageView];*/
    
    
    
    UILabel * nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    nameLabel.font = [UIFont boldSystemFontOfSize:18];
    nameLabel.numberOfLines = 0;
    //nameLabel.lineBreakMode = UILineBreakModeWordWrap;
    nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.shadowOffset = CGSizeMake(1, 1);
    nameLabel.textColor = [UIColor blackColor];
    [cell.contentView addSubview:nameLabel];
    if([self.buddy.displayName length])
    {
        nameLabel.text = self.buddy.displayName;
    }
    else{
        nameLabel.text = self.buddy.username;
    }
    
    [nameLabel sizeToFit];
    
    CGFloat xPos = buddyImageView.frame.size.width + buddyImageView.frame.origin.x + 10;
    
    CGRect tempFrame = nameLabel.frame;
    tempFrame.size.width = cell.contentView.frame.size.width -xPos;
    tempFrame.origin = CGPointMake(xPos, 5.0);
    nameLabel.frame = tempFrame;
    
    TTTAttributedLabel * statusMessageLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setObject:(id)[statusMessageLabel.textColor CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
    statusMessageLabel.linkAttributes = mutableLinkAttributes;
    statusMessageLabel.delegate = self;
    statusMessageLabel.enabledTextCheckingTypes = UIDataDetectorTypeLink;
    statusMessageLabel.numberOfLines = 0;
    statusMessageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    statusMessageLabel.adjustsFontSizeToFitWidth = YES;
    statusMessageLabel.backgroundColor = [UIColor clearColor];
    statusMessageLabel.shadowOffset = CGSizeMake(1, 1);
    statusMessageLabel.textColor = [UIColor blackColor];
    statusMessageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:statusMessageLabel];
    statusMessageLabel.text = self.buddy.statusMessage;
    
    tempFrame = statusMessageLabel.frame;
    tempFrame.size.width = cell.contentView.frame.size.width -xPos - 5.0;
    double yPos = nameLabel.frame.origin.y+nameLabel.frame.size.height+5.0;
    tempFrame.size.height = (buddyImageView.frame.origin.y+buddyImageView.frame.size.height)-yPos;
    tempFrame.origin = CGPointMake(xPos, yPos);
    statusMessageLabel.frame = tempFrame;
}

-(void)doneButtonPressed:(id)sender
{
    /*FIXMEif (self.account.isConnected) {
        NSString * newDisplayName = [displayNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([newDisplayName length] && ![newDisplayName isEqualToString:self.buddy.displayName]) {
            self.buddy.displayName = newDisplayName;
            
            id<OTRXMPPProtocol> protocol = (id<OTRXMPPProtocol>)[[OTRProtocolManager sharedInstance] protocolForAccount:self.buddy.account];
            [protocol setDisplayName:newDisplayName forBuddy:self.buddy];
            
            
        }
    }*/
    
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)removeBuddyButtonPressed:(id)sender
{
    [[[OTRProtocolManager sharedInstance] protocolForAccount:self.account] removeBuddies:@[self.buddy]];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
-(void)blockBuddyButtonPressed:(id)sender
{
    [[[OTRProtocolManager sharedInstance] protocolForAccount:self.account] blockBuddies:@[self.buddy]];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [displayNameTextField resignFirstResponder];
    
    return NO;
}

-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    UIActivityViewController *activityViewController = [UIActivityViewController otr_linkActivityViewControllerWithURLs:@[url]];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        activityViewController.popoverPresentationController.sourceView = label;
        activityViewController.popoverPresentationController.sourceRect = label.bounds;
    }
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

@end
