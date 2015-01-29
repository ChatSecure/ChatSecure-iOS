//
//  OTRBuddyInfoCell.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBroadcastInfoCell.h"

#import "OTRBroadcastGroup.h"
#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRXMPPBuddy.h"
#import "Strings.h"
#import "PureLayout.h"
#import "OTRDatabaseManager.h"


const CGFloat OTRBroadcastListCellPadding = 12.0;

@interface OTRBroadcastInfoCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *membersOfBroadcastList;

@end

@implementation OTRBroadcastInfoCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:self.nameLabel];
        
        self.membersOfBroadcastList = [[UILabel alloc] init];
        self.membersOfBroadcastList.textColor = [UIColor colorWithWhite:.45 alpha:1.0];
        self.membersOfBroadcastList.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        self.membersOfBroadcastList.adjustsFontSizeToFitWidth = YES;
        self.membersOfBroadcastList.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.membersOfBroadcastList];
                
    }
    return self;
}

/*
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
*/
 - (void)setBroadcastGroup:(OTRBroadcastGroup *)broadcastgroup
 {
     //if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
     //    if(!((OTRXMPPBuddy *)buddy).isPendingApproval) {
     
     NSString * displayName = broadcastgroup.displayName;
     
     if ([displayName length]) {
         self.nameLabel.text = displayName;
         //self.identifierLabel.text = accountName;
     
     }
     else {
         self.nameLabel.text = LIST_OF_DIFUSSION_STRING;
         //self.identifierLabel.text = nil;
     }
    
   
     NSMutableArray *members = [[NSMutableArray alloc] init];
     for (OTRBuddy *buddy in broadcastgroup.buddies)
     {
         if([buddy.displayName length])
         {
             [members addObject:buddy.displayName];
         }
         else{
             [members addObject:buddy.username];
         }
     }
     
     self.membersOfBroadcastList.text = [members componentsJoinedByString:@", "];
     
     //   }
     //NSString *pendingString = [NSString stringWithFormat:@" - %@",PENDING_APPROVAL_STRING];
     //self.nameLabel.text = [self.nameLabel.text stringByAppendingString:pendingString];
     
     //}
     [self setNeedsUpdateConstraints];
 }

- (void)updateConstraints
{
    
    
    NSArray *textLabelsArray = @[self.nameLabel,self.membersOfBroadcastList];
    
    //same horizontal contraints for all labels
    for(UILabel *label in textLabelsArray) {
        [label autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:(OTRBroadcastListCellPadding)relation:NSLayoutRelationGreaterThanOrEqual];
        [label autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:OTRBroadcastListCellPadding relation:NSLayoutRelationGreaterThanOrEqual];
    }
    
    [self.nameLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:OTRBroadcastListCellPadding];
    
    [self.membersOfBroadcastList autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.nameLabel withOffset:0 relation:NSLayoutRelationGreaterThanOrEqual];
    
    [super updateConstraints];
    
}


+ (NSString *)reuseIdentifier
{
    return NSStringFromClass([self class]);
}

@end
