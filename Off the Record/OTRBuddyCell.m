//
//  OTRBuddyCell.m
//  Off the Record
//
//  Created by David Chiles on 12/16/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyCell.h"

#import "OTRManagedBuddy.h"
#import "OTRImages.h"
#import "OTRManagedAccount.h"

@implementation OTRBuddyCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

- (id)initWithBuddy:(OTRManagedBuddy *)newBuddy reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [self initWithReuseIdentifier:reuseIdentifier]) {
        self.buddy = newBuddy;
    }
    return self;
}

-(void)setBuddy:(OTRManagedBuddy *)buddy
{
    _buddy = buddy;
    
    if (_buddy) {
        NSString *buddyUsername = _buddy.displayName;
        if (![_buddy.displayName length]) {
            buddyUsername = _buddy.accountName;
        }
        
        OTRBuddyStatus buddyStatus = OTRBuddyStatusOffline;
        OTRManagedStatus * status = [_buddy currentStatusMessage];
        if (status) {
            buddyStatus = status.statusValue;
        }
        
        self.textLabel.text = buddyUsername;
        self.accessibilityLabel = buddyUsername;
        
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        
        if (self.showStatus) {
            self.detailTextLabel.text = [OTRManagedStatus statusMessageWithStatus:buddyStatus];
        }
        else if (buddy.account.displayName.length) {
            self.detailTextLabel.text = buddy.account.displayName;
        }
        else {
            self.detailTextLabel.text = buddy.account.username;

        }
        
        switch(buddyStatus)
        {
            case OTRBuddyStatusAway:
            case OTRBuddyStatusXa:
            case OTRBuddyStatusDnd:
            case OTRBuddyStatusAvailable:
                self.textLabel.textColor = [UIColor darkTextColor];
                break;
            default:
                self.textLabel.textColor = [UIColor lightGrayColor];
                break;
        }
        
        self.imageView.image = [OTRImages statusImageWithStatus:buddyStatus];
    }
    else {
        self.accessoryView = nil;
        self.detailTextLabel.text = nil;
        self.textLabel.text = nil;
        self.imageView.image = nil;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}




@end
