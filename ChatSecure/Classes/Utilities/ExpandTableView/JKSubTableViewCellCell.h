//
//  JKSubTableViewCellCell.h
//  ExpandTableView
//
//  Created by Jack Kwok on 7/5/13.
//  Copyright (c) 2013 Jack Kwok. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JKSubTableViewCellCell : UITableViewCell {
    UIImageView *iconImage;
    UILabel *titleLabel;
    UIImageView *selectionIndicatorImg;
}

@property (nonatomic,strong) UIImageView *iconImage;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UIImageView *selectionIndicatorImg;


- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void)setupDisplay;
- (void)setCellForegroundColor:(UIColor *) foregroundColor;
- (void)setCellBackgroundColor:(UIColor *) backgroundColor;

@end
