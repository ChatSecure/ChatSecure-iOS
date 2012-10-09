//
//  InLineTextEditTableViewCell.m
//  Off the Record
//
//  Created by David on 10/2/12.
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

#import "OTRInLineTextEditTableViewCell.h"

#define textLeftFieldBuffer 100

@implementation OTRInLineTextEditTableViewCell

@synthesize textField = _textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

-(id)initWithTextField:(UITextField *)cellTextField textLabeltext:(NSString *)name reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    self.textField = cellTextField;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.tag = 999;
    
    self.textLabel.text = name;
    
    
}

-(void)setTextField:(UITextField *)newTextField
{
    [[self.contentView viewWithTag:999] removeFromSuperview];
    _textField = newTextField;
    [self layoutIfNeeded];
    self.textField.frame = CGRectMake(textLeftFieldBuffer, self.textLabel.frame.origin.y, self.contentView.frame.size.width-textLeftFieldBuffer-5, self.contentView.frame.size.height-20);
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.textField.tag = 999;
    [self.contentView addSubview:self.textField];
}

-(void)dealloc {
    self.textField = nil;
}

@end
