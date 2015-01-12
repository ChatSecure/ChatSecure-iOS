//
//  JKSingleSelectSubTableViewCell.m
//  ExpandTableView
//
//  Created by Jack Kwok on 7/5/13.
//  Copyright (c) 2013 Jack Kwok. All rights reserved.
//

#import "JKSingleSelectSubTableViewCell.h"
#import "JKSubTableViewCellCell.h"

@implementation JKSingleSelectSubTableViewCell

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    JKSubTableViewCellCell *cell = (JKSubTableViewCellCell *)[tableView cellForRowAtIndexPath:indexPath];
    BOOL isSwitchedOn = YES;
    BOOL isRowSelected = !(cell.selectionIndicatorImg.hidden);
    
    if(isRowSelected){
        cell.selectionIndicatorImg.hidden = YES;
        isSwitchedOn = NO;
    } else {
        cell.selectionIndicatorImg.hidden = NO;
        isSwitchedOn = YES;
        
        // deselect previously selected siblings
        NSInteger numberOfChild = [delegate numberOfChildrenUnderParentIndex:self.parentIndex];
        
        for (int i = 0; i < numberOfChild ; i++) {
            if (i != [indexPath row]) {
                BOOL isRowSelected = [self.delegate isSelectedForChildIndex:i underParentIndex:self.parentIndex];
                if (isRowSelected) {
                    NSIndexPath *siblingIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    JKSubTableViewCellCell *siblingCell = (JKSubTableViewCellCell *)[tableView cellForRowAtIndexPath:siblingIndexPath];
                    siblingCell.selectionIndicatorImg.hidden = YES;
                    [self.delegate didSelectRowAtChildIndex:i selected:NO underParentIndex:self.parentIndex];
                }
            }
        }
    }
    
    [self.delegate didSelectRowAtChildIndex:indexPath.row selected:isSwitchedOn underParentIndex:self.parentIndex];
}

@end
