//
//  JKSubTableViewCell.m
//  ExpandTableView
//
//  Created by Jack Kwok on 7/20/13.
//  Copyright (c) 2013 Jack Kwok. All rights reserved.
//

#import "JKSubTableViewCell.h"
#import "JKSubTableViewCellCell.h"

@implementation JKSubTableViewCell

@synthesize insideTableView, selectionIndicatorImg;

#define HEIGHT_FOR_CELL 44.0

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.insideTableView = [[UITableView alloc] init];
        insideTableView.dataSource = self;
        insideTableView.delegate = self;
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [[self contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self.insideTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        insideTableView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
        fgColor = [UIColor darkTextColor];
        bgColor = [UIColor clearColor];
        font = [UIFont systemFontOfSize:16.0];
        insideTableView.backgroundColor = [UIColor clearColor];
        insideTableView.scrollEnabled = NO;
        [self.contentView addSubview:self.insideTableView];
    }
    return self;
}

- (id) getDelegate {
    return delegate;
}

// TODO combine set delegate and parentIndex into one method for better safety
- (void) setDelegate:(id<JKSubTableViewCellDelegate>)deleg {
    delegate = deleg;
    NSInteger numberOfChild = [delegate numberOfChildrenUnderParentIndex:self.parentIndex];
    insideTableView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, HEIGHT_FOR_CELL * numberOfChild);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(UIColor *) getSubTableForegroundColor {
    return fgColor;
}

-(void) setSubTableForegroundColor:(UIColor *)p_fgColor {
    fgColor = p_fgColor;
}

-(UIColor *) getSubTableBackgroundColor {
    return bgColor;
}

-(void) setSubTableBackgroundColor:(UIColor *)p_bgColor {
    bgColor = p_bgColor;
}

-(UIFont *) getSubTableFont {
    return font;
}

-(void) setSubTableFont:(UIFont *) p_font  {
    font = p_font;
}

- (UIImage *) selectionIndicatorImgOrDefault {
    if (!self.selectionIndicatorImg) {
        self.selectionIndicatorImg = [UIImage imageNamed:@"checkmark"];
    }
    return self.selectionIndicatorImg;
}

- (void) reload {
    [self.insideTableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.delegate numberOfChildrenUnderParentIndex:self.parentIndex];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SubTableViewCellCell_Reuse_Id";
    
    JKSubTableViewCellCell *cell = (JKSubTableViewCellCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[JKSubTableViewCellCell alloc] initWithReuseIdentifier:CellIdentifier];
    } else {
        NSLog(@"reusing existing JKSubTableViewCellCell");
    }
    
    NSInteger row = [indexPath row];
    cell.titleLabel.text = [self.delegate labelForChildIndex:row underParentIndex:self.parentIndex];
    cell.iconImage.image = [self.delegate iconForChildIndex:row underParentIndex:self.parentIndex];
    cell.selectionIndicatorImg.image = [self selectionIndicatorImgOrDefault];
    
    BOOL isRowSelected = [self.delegate isSelectedForChildIndex:row underParentIndex:self.parentIndex];
    
    if (isRowSelected) {
        cell.selectionIndicatorImg.hidden = NO;
    } else {
        cell.selectionIndicatorImg.hidden = YES;
    }
    
    [cell setCellBackgroundColor:bgColor];
    [cell setCellForegroundColor:fgColor];
    [cell.titleLabel setFont:font];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    //[cell setupDisplay];
    return cell;
}



#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return HEIGHT_FOR_CELL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // must be implemented by concrete subclasses
}

@end
