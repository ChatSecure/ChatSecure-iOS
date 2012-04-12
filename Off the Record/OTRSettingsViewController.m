//
//  OTRSettingsViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingsViewController.h"
#import "OTRProtocolManager.h"
#import "OTRBoolSetting.h"
#import "Strings.h"

@implementation OTRSettingsViewController
@synthesize settingsTableView, settingsManager;

- (void) dealloc
{
    self.settingsManager = nil;
}

- (id) init
{
    if (self = [super init])
    {
        self.title = SETTINGS_STRING;
        self.tabBarItem.image = [UIImage imageNamed:@"19-gear.png"];
        self.settingsManager = [OTRProtocolManager sharedInstance].settingsManager;
    }
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.settingsTableView = nil;
}

- (void)loadView
{
    [super loadView];
    self.settingsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.settingsTableView.dataSource = self;
    self.settingsTableView.delegate = self;
    self.settingsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:settingsTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.settingsTableView.frame = self.view.bounds;
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

#pragma mark UITableViewDataSource methods

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}
    OTRSetting *setting = [settingsManager settingAtIndexPath:indexPath];
    
    cell.textLabel.text = setting.title;
    cell.detailTextLabel.text = setting.description;
    if(setting.imageName)
    {
        cell.imageView.image = [UIImage imageNamed:setting.imageName];
    }
    else 
    {
        cell.imageView.image = nil;
    }
    
    UIView *accessoryView = nil;
    if ([setting isKindOfClass:[OTRBoolSetting class]]) {
        OTRBoolSetting *boolSetting = (OTRBoolSetting*)setting;
        accessoryView = boolSetting.boolSwitch;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } 
    else if ([setting isKindOfClass:[OTRViewSetting class]])
    {
        OTRViewSetting *viewSetting = (OTRViewSetting*)setting;
        viewSetting.delegate = self;
        accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    }
    cell.accessoryView = accessoryView;
    
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return [self.settingsManager.settingsGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return [self.settingsManager numberOfSettingsInSection:sectionIndex];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.settingsManager stringForGroupInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRSetting *setting = [self.settingsManager settingAtIndexPath:indexPath];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [setting performSelector:setting.action];
#pragma clang diagnostic pop
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark OTRSettingViewDelegate method
- (void) showViewControllerClass:(Class)viewControllerClass
{
    UIViewController *viewController = [[viewControllerClass alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
