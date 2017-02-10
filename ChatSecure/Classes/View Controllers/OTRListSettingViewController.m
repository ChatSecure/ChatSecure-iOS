//
//  OTRListSettingViewController.m
//  Off the Record
//
//  Created by David on 11/13/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRListSettingViewController.h"
#import "OTRListSettingValue.h"
#import "OTRListSetting.h"

@import PureLayout;

@interface OTRListSettingViewController ()

@property (nonatomic, strong) id currentSelectedValue;
@property (nonatomic) BOOL addedConstratints;

@property (nonatomic,strong) OTRListSetting * otrSetting;
@property (nonatomic,strong) NSIndexPath * selectedPath;
@property (nonatomic,strong) UITableView * valueTable;

@end

@implementation OTRListSettingViewController
@synthesize otrSetting = _otrSetting;

-(void) viewDidLoad
{
    [super viewDidLoad];
    self.addedConstratints = NO;
    self.valueTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.valueTable.delegate = self;
    self.valueTable.dataSource = self;
    self.valueTable.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.currentSelectedValue = [self.otrSetting value];
    
    self.selectedPath = [NSIndexPath indexPathForRow:[self.otrSetting indexOfValue:self.currentSelectedValue] inSection:0];
    
    [self.view addSubview:self.valueTable];
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints
{
    [super updateViewConstraints];
    if (!self.addedConstratints) {
        [self.valueTable autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
        self.addedConstratints = YES;
    }
}

-(void)save:(id)sender
{
    [self.otrSetting setValue:self.currentSelectedValue];
    [super save:sender];
}

#pragma mark UITableViewDataSource methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.otrSetting.possibleValues count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    OTRListSettingValue *listSettingValue = [self.otrSetting.possibleValues objectAtIndex:indexPath.row];
    cell.textLabel.text = listSettingValue.title;
    cell.detailTextLabel.text = listSettingValue.detail;
    if ([indexPath isEqual:self.selectedPath]) {
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
    OTRListSettingValue *listSettingValue = [self.otrSetting.possibleValues objectAtIndex:indexPath.row];
    self.currentSelectedValue = listSettingValue.value;
    [self.valueTable reloadData];
    [self.valueTable selectRowAtIndexPath:self.selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
