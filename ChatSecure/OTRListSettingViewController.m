//
//  OTRListSettingViewController.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRListSettingViewController.h"

@interface OTRListSettingViewController ()

@end

@implementation OTRListSettingViewController

@synthesize valueTable;
@synthesize selectedPath;
@synthesize otrSetting;

- (void)dealloc
{
    valueTable = nil;
    selectedPath =nil;
    otrSetting = nil;
}

- (id)init
{
    if (self = [super init])
    {
        self.valueTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.valueTable.delegate = self;
        self.valueTable.dataSource = self;
    }
    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    self.valueTable.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.valueTable.frame = self.view.frame;
    
    newValue = [otrSetting value];
    oldValue = [otrSetting value];
    
    self.selectedPath = [NSIndexPath indexPathForRow:[otrSetting.possibleValues indexOfObject:newValue] inSection:0];
    
    [self.view addSubview:self.valueTable];
    

}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    valueTable.frame = self.view.bounds;
}

-(void)save:(id)sender
{
    [otrSetting setValue:newValue];
    [super save:sender];
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [otrSetting.possibleValues count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = [self.otrSetting.possibleValues objectAtIndex:indexPath.row];
    if ([indexPath isEqual:selectedPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedPath = indexPath;
    newValue = [self.otrSetting.possibleValues objectAtIndex:indexPath.row];
    [self.valueTable reloadData];
    [self.valueTable selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
