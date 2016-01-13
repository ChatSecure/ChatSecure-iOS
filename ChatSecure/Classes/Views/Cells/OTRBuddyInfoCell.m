//
//  OTRBuddyInfoCell.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyInfoCell.h"

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRXMPPBuddy.h"
#import "OTRStrings.h"
#import "PureLayout.h"
#import "OTRDatabaseManager.h"
#import "OTRLanguageManager.h"

@interface OTRBuddyInfoCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *identifierLabel;
@property (nonatomic, strong) UILabel *accountLabel;

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
        
        self.accountLabel = [[UILabel alloc] initForAutoLayout];
        self.accountLabel.textColor = [UIColor colorWithWhite:.55 alpha:1.0];
        self.accountLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.accountLabel.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:self.accountLabel];
        
    }
    return self;
}

- (void)setThread:(id<OTRThreadOwner>)thread withAccountName:(NSString *)accountName
{
    [self setThread:thread];
    if ([accountName length]) {
        if ([self.identifierLabel.text length]) {
            self.accountLabel.text = accountName;
        }
        else {
            self.identifierLabel.text = accountName;
            self.accountLabel.text = nil;
        }
    }
}

- (void)setThread:(id<OTRThreadOwner>)thread
{
    [super setThread:thread];
    
    NSString * name = [thread threadName];
    
    self.nameLabel.text = name;
    self.identifierLabel.text = nil;
    
    if ([thread isKindOfClass:[OTRXMPPBuddy class]]) {
        if(((OTRXMPPBuddy *)thread).isPendingApproval) {
            NSString *pendingString = [NSString stringWithFormat:@" - %@",PENDING_APPROVAL_STRING];
            self.nameLabel.text = [self.nameLabel.text stringByAppendingString:pendingString];
        }
    }
}

- (void)updateConstraints
{

    if (!self.addedConstraints) {
        NSArray *textLabelsArray = @[self.nameLabel,self.identifierLabel,self.accountLabel];
        
        //same horizontal contraints for all labels
        for(UILabel *label in textLabelsArray) {
            [label autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.avatarImageView withOffset:OTRBuddyImageCellPadding];
            [label autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:OTRBuddyImageCellPadding relation:NSLayoutRelationGreaterThanOrEqual];
        }
        
        [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:OTRBuddyImageCellPadding];
        
        [self.identifierLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.identifierLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.accountLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        
        [self.accountLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:OTRBuddyImageCellPadding];
    }
    [super updateConstraints];
}

@end
