//
//  OTRTextFieldTableViewCell.m
//  Off the Record
//
//  Created by David Chiles on 4/30/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRTextFieldTableViewCell.h"

@implementation OTRTextFieldTableViewCell

- (void)setTextField:(UITextField *)textField
{
    if (_textField) {
        [_textField removeFromSuperview];
    }
    
    _textField = textField;
    
    if (self.textField) {
        self.textField.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
        [self.contentView addSubview:self.textField];
    }
}

@end
