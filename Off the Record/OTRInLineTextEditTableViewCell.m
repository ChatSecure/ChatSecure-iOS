//
//  InLineTextEditTableViewCell.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRInLineTextEditTableViewCell.h"

#define textLeftFieldBuffer 100

@implementation OTRInLineTextEditTableViewCell

@synthesize textField = _textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        
    }
    return self;
}

-(id)initWithTextField:(UITextField *)cellTextField textLabeltext:(NSString *)name reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    self.textField = cellTextField;
    self.textField.tag = 999;
    self.textLabel.text = name;
    [self layoutIfNeeded];
    
    self.textField.frame = CGRectMake(textLeftFieldBuffer, self.textLabel.frame.origin.y, self.contentView.frame.size.width-textLeftFieldBuffer, self.contentView.frame.size.height-20);
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.contentView addSubview:self.textField];
    
}

-(void)setTextField:(UITextField *)newTextField
{
    [[self.contentView viewWithTag:999] removeFromSuperview];
    _textField = newTextField;
    [self layoutIfNeeded];
    self.textField.frame = CGRectMake(textLeftFieldBuffer, self.textLabel.frame.origin.y, self.contentView.frame.size.width-textLeftFieldBuffer, self.contentView.frame.size.height-20);
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.textField.tag = 999;
    [self.contentView addSubview:self.textField];
}

-(void)dealloc {
    self.textField = nil;
}

@end
