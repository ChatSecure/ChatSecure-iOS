//
//  OTRMessagesCollectionViewCell.m
//  Off the Record
//
//  Created by David Chiles on 6/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesCollectionViewCell.h"

@interface OTRMessagesCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *errorImageView;

@property (weak, nonatomic) IBOutlet UIImageView *lockImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lockHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lockBottomConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation OTRMessagesCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UITapGestureRecognizer *tapg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(errorImageTap:)];
    [self.errorImageView addGestureRecognizer:tapg];
    self.tap = tapg;
}

- (void)errorImageTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(messagesCollectionViewCellDidTapError:)]) {
        [self.delegate messagesCollectionViewCellDidTapError:self];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    BOOL result = [super canPerformAction:action withSender:sender];
    if (!result) {
        result = (action == @selector(delete:));
    }
    return result;
}

- (void)delete:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(messagesCollectionViewCellDidTapDelete:)]) {
        [self.delegate messagesCollectionViewCellDidTapDelete:self];
    }
}

- (void)updateConstraints
{
    [super updateConstraints];
    if (!self.lockImageView.image) {
        self.lockHeightConstraint.constant = 0.0;
        self.lockBottomConstraint.constant = 0.0;
    }
    else {
        self.lockHeightConstraint.constant = 20.0;
        self.lockBottomConstraint.constant = 8.0;
    }
}

@end
