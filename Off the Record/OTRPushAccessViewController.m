//
//  OTRPushAccessViewController.m
//  Off the Record
//
//  Created by Christopher Ballinger on 10/20/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
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

#import "OTRPushAccessViewController.h"

@interface OTRPushAccessViewController ()

@end

#define ACCOUNT_IDS_SECTION 0
#define PATS_SECTION 1

@implementation OTRPushAccessViewController
@synthesize tokenTableView, pushController, accountIDs, pats;

- (id)init {
    if (self = [super init]) {
        self.tokenTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.tokenTableView.delegate = self;
        self.tokenTableView.dataSource = self;
        self.pushController = [OTRPushController sharedInstance];
        self.accountIDs = [pushController accountIDs];
        self.pats = [pushController pats];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.view addSubview:tokenTableView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tokenTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == ACCOUNT_IDS_SECTION) {
        return [accountIDs count];
    } else if (section == PATS_SECTION) {
        return [pats count];
    }
    return 0;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    if (indexPath.section == ACCOUNT_IDS_SECTION) {
    
    }
    else if (indexPath.section == PATS_SECTION) {
        NSDictionary *pat = [pats objectAtIndex:indexPath.row];
        cell.textLabel.text = [pat objectForKey:@"name"];
        cell.detailTextLabel.text = [pat objectForKey:@"pat"];
    }
    
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
