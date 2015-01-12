//
//  OTRBuddyInfoCell.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyListCell.h"

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRXMPPBuddy.h"
#import "Strings.h"
#import "PureLayout.h"
#import "OTRDatabaseManager.h"


const CGFloat OTRBuddyListImageCellPadding = 12.0;

@interface OTRBuddyListCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *identifierLabel;
@property (nonatomic, strong) UILabel *accountLabel;


@end

@implementation OTRBuddyListCell

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
        
        self.button = [[BFPaperCheckbox alloc]initWithFrame:CGRectMake(0, 0, 30, 50)];
        self.identifierLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.button.checkmarkColor = [UIColor blueColor];
        self.button.enabled = NO;
        [self.contentView addSubview:self.button];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        
    }
    return self;
}

- (void)setBuddy:(OTRBuddy *)buddy withAccountName:(NSString *)accountName
{
    [self setBuddy:buddy];
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

- (void)setBuddy:(OTRBuddy *)buddy
{
    //if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
    //    if(!((OTRXMPPBuddy *)buddy).isPendingApproval) {
    
    [super setBuddy:buddy];
    
    NSString * displayName = buddy.displayName;
    NSString * accountName = buddy.username;
    NSString * statusMessage = buddy.statusMessage;
    
    if ([displayName length]) {
        self.nameLabel.text = displayName;
        //self.identifierLabel.text = accountName;
        self.identifierLabel.text = statusMessage;
    }
    else {
        self.nameLabel.text = accountName;
        //self.identifierLabel.text = nil;
        self.identifierLabel.text = statusMessage;
    }
    
    [self.button uncheckAnimated:NO];
    
     //   }
    //NSString *pendingString = [NSString stringWithFormat:@" - %@",PENDING_APPROVAL_STRING];
    //self.nameLabel.text = [self.nameLabel.text stringByAppendingString:pendingString];
       
    //}
}

- (void)updateConstraints
{

    if (!self.addedConstraints) {
        NSArray *textLabelsArray = @[self.nameLabel,self.identifierLabel,self.accountLabel];
        
        //same horizontal contraints for all labels
        for(UILabel *label in textLabelsArray) {
            [label autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.avatarImageView withOffset:OTRBuddyImageCellPadding];
            [label autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:OTRBuddyListImageCellPadding relation:NSLayoutRelationGreaterThanOrEqual];
        }
        
        [self.button autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.avatarImageView withOffset:200.0f];
        [self.button autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:OTRBuddyListImageCellPadding relation:NSLayoutRelationGreaterThanOrEqual];
        
        [self.button autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.avatarImageView];
        
        [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:OTRBuddyListImageCellPadding];
        
        [self.identifierLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        [self.identifierLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.accountLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
        
        [self.accountLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:OTRBuddyImageCellPadding];
        [self.button autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:OTRBuddyImageCellPadding];
        [self.button autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:OTRBuddyImageCellPadding];
        

        
        
        
     
        
        
    }
    [super updateConstraints];
}

@end
