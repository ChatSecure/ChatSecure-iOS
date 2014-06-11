//
//  OTRMessagesCollectionViewCell.m
//  Off the Record
//
//  Created by David Chiles on 6/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesCollectionViewCell.h"

@interface OTRMessagesCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIView *leftRightView;

@property (nonatomic, strong) UIImageView *errorImageView;

@property (nonatomic, strong) UIImageView *deliveredImageView;

@property (nonatomic, strong) UIImageView *lockImageView;

@property (nonatomic, strong) NSLayoutConstraint *lockWidthConstraint;

@property (nonatomic, strong) NSLayoutConstraint *deliveredWidthConstraint;

@property (nonatomic, strong) NSLayoutConstraint *errorWidthConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation OTRMessagesCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.errorImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.errorImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.deliveredImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.deliveredImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.lockImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.lockImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    [self.leftRightView addSubview:self.errorImageView];
    [self.leftRightView addSubview:self.deliveredImageView];
    [self.leftRightView addSubview:self.lockImageView];
    
    [self setupConstraints];
    
    
    UITapGestureRecognizer *tapg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(errorImageTap:)];
    [self.errorImageView addGestureRecognizer:tapg];
    self.tap = tapg;
}

- (void)setupConstraints
{
    [self.leftRightView addConstraint:[NSLayoutConstraint constraintWithItem:self.errorImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.leftRightView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self.leftRightView addConstraint:[NSLayoutConstraint constraintWithItem:self.deliveredImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.leftRightView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self.leftRightView addConstraint:[NSLayoutConstraint constraintWithItem:self.lockImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.leftRightView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    
    [self.lockImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.lockImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:24.0]];
    [self.errorImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.errorImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:33.0]];
    [self.deliveredImageView addConstraint:[NSLayoutConstraint constraintWithItem:self.deliveredImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:24.0]];
    
    
    self.lockWidthConstraint = [NSLayoutConstraint constraintWithItem:self.lockImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
    [self.lockImageView addConstraint:self.lockWidthConstraint];
    
    self.deliveredWidthConstraint = [NSLayoutConstraint constraintWithItem:self.deliveredImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
    [self.deliveredImageView addConstraint:self.deliveredWidthConstraint];
    
    self.errorWidthConstraint = [NSLayoutConstraint constraintWithItem:self.errorImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0.0];
    [self.errorImageView addConstraint:self.errorWidthConstraint];
    
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
        self.lockWidthConstraint.constant = 0.0;
    }
    else {
        self.lockWidthConstraint.constant = 24.0;
    }
    
    if (!self.errorImageView.image){
        self.errorWidthConstraint.constant = 0.0;
    }
    else{
        self.errorWidthConstraint.constant = 33.0;
    }
    
    if (!self.deliveredImageView.image) {
        self.deliveredWidthConstraint.constant = 0.0;
    }
    else {
        self.deliveredWidthConstraint.constant = 24.0;
    }
}

@end
