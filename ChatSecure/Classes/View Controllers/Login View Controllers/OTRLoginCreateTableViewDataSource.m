//
//  OTRLoginCreateTableViewDataSource.m
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRLoginCreateTableViewDataSource.h"
#import "OTRLOginCreateViewController.h"
#import "OTRTextFieldTableViewCell.h"


@implementation OTRLoginCreateTableViewDataSource

- (instancetype)initWithBasicInfoArray:(NSArray *)basicInfoArray advancedArray:(NSArray *)advancedInfoArray
{
    if (self = [self init]) {
        self.basicInfoArray = basicInfoArray;
        self.advancedInfoArray = advancedInfoArray;
    }
    
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.basicInfoArray count] && [self.advancedInfoArray count]) {
        return 2;
    }
    
    if ([self.basicInfoArray count]) {
        return 1;
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.basicInfoArray count];
    } else {
        return [self.advancedInfoArray count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTRLoginCellInfo *cellInfo = nil;
    if (indexPath.section == 0) {
        cellInfo = self.basicInfoArray[indexPath.row];
    } else {
        cellInfo = self.advancedInfoArray[indexPath.row];
    }
    
    OTRCellType cellType = cellInfo.cellType;
    NSString *identifier = [NSString stringWithFormat:@"Cell-%lu",(unsigned long)cellType];
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cellType == OTRCellTypeSwitch)
    {
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        }
        cell.textLabel.text = cellInfo.labelText;
        cell.accessoryView  = cellInfo.inputView;
        
    }
    else if(cellType == OTRCellTypeHelp)
    {
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
            
            //[cell.contentView addSubview:[cellInfo objectForKey:kTextLabelTextKey]];
            cell.accessoryView = cellInfo.inputView;
        }
        
    }
    else if(cellType == OTRCellTypeTextField)
    {
        if(!cell)
        {
            cell = [[OTRTextFieldTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        }
        [cell layoutIfNeeded];
        ((OTRTextFieldTableViewCell *)cell).textField = (JVFloatLabeledTextField *)cellInfo.inputView;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end
