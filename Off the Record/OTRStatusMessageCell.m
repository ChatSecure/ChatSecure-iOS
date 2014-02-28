//
//  OTRStatusMessageCell.m
//  Off the Record
//
//  Created by David on 4/18/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRStatusMessageCell.h"
#import "OTRConstants.h"

@implementation OTRStatusMessageCell

@synthesize statusMessageLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        statusMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        
        statusMessageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        statusMessageLabel.textColor = [UIColor grayColor];
        statusMessageLabel.textAlignment = NSTextAlignmentCenter;
        statusMessageLabel.font = [UIFont boldSystemFontOfSize:kOTRSentDateFontSize];
        statusMessageLabel.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:statusMessageLabel];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.statusMessageLabel.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
}

@end
