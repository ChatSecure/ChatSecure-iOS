//
//  OTRTextFieldTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 4/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRTextFieldTableViewCell.h"
#import "JVFloatLabeledTextField.h"
#import "PureLayout.h"

@implementation OTRTextFieldTableViewCell

- (void)setTextField:(JVFloatLabeledTextField *)textField
{
    if (_textField) {
        [_textField removeFromSuperview];
    }
    _textField = textField;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat textFieldHeight = 43.5;
    CGFloat textFieldLeftMargin = 15.0;
    CGFloat textFieldRightMargin = 20.0;
    [self.contentView addSubview:self.textField];
    [self.textField autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:textFieldLeftMargin];
    [self.textField autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:textFieldRightMargin];
    [self.textField autoSetDimension:ALDimensionHeight toSize:textFieldHeight];
    [self.textField autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
}


+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
