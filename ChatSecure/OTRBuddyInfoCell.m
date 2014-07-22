//
//  OTRBuddyInfoCell.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyInfoCell.h"

#import "OTRBuddy.h"
#import "OTRXMPPBuddy.h"
#import "Strings.h"

@interface OTRBuddyInfoCell ()

@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UILabel *identifierLabel;

@end

@implementation OTRBuddyInfoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:self.nameLabel];
        
        self.identifierLabel = [[UILabel alloc] init];
        self.identifierLabel.textColor = [UIColor colorWithWhite:.45 alpha:1.0];
        self.identifierLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.identifierLabel.adjustsFontSizeToFitWidth = YES;
        self.identifierLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.identifierLabel];
        
    }
    return self;
}

- (void)setBuddy:(OTRBuddy *)buddy
{
    [super setBuddy:buddy];
    
    NSString * displayName = buddy.displayName;
    NSString * accountName = buddy.username;
    
    if ([displayName length]) {
        self.nameLabel.text = displayName;
        self.identifierLabel.text = accountName;
    }
    else {
        self.nameLabel.text = accountName;
        self.identifierLabel.text = nil;
    }
    
    if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
        if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
            NSString *pendingString = [NSString stringWithFormat:@" - %@",PENDING_APPROVAL_STRING];
            self.nameLabel.text = [self.nameLabel.text stringByAppendingString:pendingString];
        }
    }
}

- (void)updateConstraints
{

    NSDictionary *metrics = @{@"margin":@(OTRBuddyImageCellPadding)};
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[nameLabel]->=margin-|" options:0 metrics:metrics views:@{@"nameLabel":self.nameLabel,@"imageView":self.avatarImageView}]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView]-margin-[identifierLabel]->=margin-|" options:0 metrics:metrics views:@{@"identifierLabel":self.identifierLabel,@"imageView":self.avatarImageView}]];
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-margin-[nameLabel]->=0-[identifierLabel]-margin-|" options:0 metrics:metrics views:@{@"nameLabel":self.nameLabel,@"identifierLabel":self.identifierLabel}]];
    [super updateConstraints];
     
}

@end
