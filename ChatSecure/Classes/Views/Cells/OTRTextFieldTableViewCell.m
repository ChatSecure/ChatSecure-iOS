//
//  OTRTextFieldTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 4/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRTextFieldTableViewCell.h"

#import "JVFloatLabeledTextField.h"

NSString *const OTRTextFieldTableViewCellHeight = @"OTRTextFieldTableViewCellHeightMargin";
NSString *const OTRTextFieldTableViewCellLeftMargin = @"OTRTextFieldTableViewCellLeftMargin";
NSString *const OTRTextFieldTableViewCellRightMargin = @"OTRTextFieldTableViewCellRightMargin";

@implementation OTRTextFieldTableViewCell

- (void)setTextField:(JVFloatLabeledTextField *)textField
{
    if (_textField) {
        [_textField removeFromSuperview];
    }
    _textField = textField;
    self.textField.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_textField);
    CGFloat textFieldHeight = 43.5;
    CGFloat textFieldLeftMargin = 15.0;
    CGFloat textFieldRightMargin = 20.0;
    NSDictionary *metrics = @{OTRTextFieldTableViewCellHeight:@(textFieldHeight),
                              OTRTextFieldTableViewCellLeftMargin:@(textFieldLeftMargin),
                              OTRTextFieldTableViewCellRightMargin:@(textFieldRightMargin)};
    [self.contentView addSubview:self.textField];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(OTRTextFieldTableViewCellLeftMargin)-[_textField]-(OTRTextFieldTableViewCellRightMargin)-|" options:0 metrics:metrics views:views]];
    
    [self.textField addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:textFieldHeight]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
}


+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
