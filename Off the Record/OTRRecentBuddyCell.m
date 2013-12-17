//
//  OTRRecentBuddyCell.m
//  Off the Record
//
//  Created by David Chiles on 12/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRRecentBuddyCell.h"

#import "OTRManagedBuddy.h"
#import "OTRUtilities.h"

@implementation OTRRecentBuddyCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setBuddy:(OTRManagedBuddy *)buddy
{
    [super setBuddy:buddy];
    
    NSInteger numberOfUnreadMessages = [self.buddy numberOfUnreadMessages];
    
    
    NSDate * date = buddy.lastMessageDate;
    NSString *stringFromDate = nil;
    
    if([OTRUtilities dateInLast24Hours:date])
    {
        stringFromDate = [NSDateFormatter localizedStringFromDate:buddy.lastMessageDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    }
    else if ([OTRUtilities dateInLast7Days:date])
    {
        //show day of week
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEEE"];
        stringFromDate = [formatter stringFromDate:date];
    }
    else{
        stringFromDate= [NSDateFormatter localizedStringFromDate:buddy.lastMessageDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    }
    
    self.detailTextLabel.text = stringFromDate;
    
    if (numberOfUnreadMessages>0) {
        UILabel * messageCountLabel = nil;
        if (self.accessoryView) {
            messageCountLabel = (UILabel *)self.accessoryView;
        }
        else
        {
            messageCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 42.0, 28.0)];
            messageCountLabel.backgroundColor = [UIColor darkGrayColor];
            messageCountLabel.textColor = [UIColor whiteColor];
            messageCountLabel.layer.cornerRadius = 14;
            messageCountLabel.numberOfLines = 0;
            messageCountLabel.lineBreakMode = NSLineBreakByWordWrapping;
            messageCountLabel.textAlignment = NSTextAlignmentCenter;
        }
        if (numberOfUnreadMessages > 99) {
            messageCountLabel.text = [NSString stringWithFormat:@"%d+",99];
        }
        else
        {
            messageCountLabel.text = [NSString stringWithFormat:@"%d",[buddy numberOfUnreadMessages]];
        }
        self.accessoryView = messageCountLabel;
    }
    else
    {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
