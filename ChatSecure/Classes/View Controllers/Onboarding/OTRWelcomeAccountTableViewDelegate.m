//
//  OTRWelcomeAccountTableViewDelegate.m
//  ChatSecure
//
//  Created by David Chiles on 5/7/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRWelcomeAccountTableViewDelegate.h"
#import "OTRExistingAccountViewController.h"

@implementation OTRWelcomeAccountTableViewDelegate


#pragma - mark UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.welcomeAccountInfoArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    OTRWelcomeAccountInfo *info = [self.welcomeAccountInfoArray objectAtIndex:indexPath.row];
    
    cell.imageView.image = info.image;
    cell.textLabel.text = info.labelText;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


#pragma - mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OTRWelcomeAccountInfo *info = [self.welcomeAccountInfoArray objectAtIndex:indexPath.row];
    if (info.didSelectBlock) {
        info.didSelectBlock();
    }
}

@end
