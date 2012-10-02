//
//  InLineTextEditTableViewCell.m
//  Off the Record
//
//  Created by David on 10/2/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRInLineTextEditTableViewCell.h"

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
    self.textLabel.text = name;
    [self layoutIfNeeded];
    
    self.textField.frame = CGRectMake(self.textLabel.frame.size.width+10, self.textLabel.frame.origin.y, 200, self.contentView.frame.size.height-20);
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.contentView addSubview:self.textField];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setTextField:(UITextField *)newTextField
{
    _textField = newTextField;
    self.textField.frame = CGRectMake(self.textLabel.frame.size.width+10, self.textLabel.frame.origin.y, 200, self.contentView.frame.size.height-20);
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:self.textField];
}

-(void)dealloc {
    self.textField = nil;
}

@end
