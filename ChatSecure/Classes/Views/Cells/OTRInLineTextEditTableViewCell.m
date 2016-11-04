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
#import "OTRUtilities.h"
@import PureLayout;

@interface OTRInLineTextEditTableViewCell ()

@property (nonatomic) BOOL addedConstraints;
@property (nonatomic, strong) NSArray * constraints;

@end

@implementation OTRInLineTextEditTableViewCell

-(void)setTextField:(UITextField *)newTextField
{
    if (self.textField) {
        [self.textField removeFromSuperview];
    }
    _textField = newTextField;
    _textField.translatesAutoresizingMaskIntoConstraints = NO;

    [self.constraints autoRemoveConstraints];
    self.constraints = nil;
    self.addedConstraints = NO;
    [self.contentView addSubview:self.textField];
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

-(void)updateConstraints{
    [super updateConstraints];
    if (!self.addedConstraints && self.textField) {
        
        NSLayoutConstraint *leadingEdgeConstraint = [self.textField autoPinEdge:ALEdgeLeading
                                                                          toEdge:ALEdgeTrailing
                                                                          ofView:self.textLabel
                                                                      withOffset:6];
        
        NSLayoutConstraint *trailingEdgeConstraint = [self.textField autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:5];
        
        NSLayoutConstraint *centerConstraint = [self.textField autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        
        self.constraints = @[leadingEdgeConstraint,trailingEdgeConstraint,centerConstraint];
        
        self.addedConstraints = YES;
    }
}


@end
