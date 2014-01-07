//
//  OTRSectionHeaderView.m
//  Off the Record
//
//  Created by David on 3/1/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "OTRImages.h"
#import "OTRBuddyListSectionInfo.h"

@implementation OTRSectionHeaderView

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle:)];
        [self addGestureRecognizer:tapGesture];
        self.userInteractionEnabled = YES;
        
        self.contentView.backgroundColor = [UIColor lightGrayColor];
        
        
        self.disclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.disclosureButton.frame = CGRectMake(0, 0, 20.0, 20.0);
        [self.disclosureButton setImage:[OTRImages closeCaratImage] forState:UIControlStateNormal];
        [self.disclosureButton setImage:[OTRImages openCaratImage] forState:UIControlStateSelected];
        [self.disclosureButton addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
        self.disclosureButton.userInteractionEnabled = NO;
        self.disclosureButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.disclosureButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:self.disclosureButton];
        
        [self setupContraints];
    }
    return self;
}

- (void) setSectionInfo:(OTRBuddyListSectionInfo *)sectionInfo {
    _sectionInfo = sectionInfo;
    self.textLabel.text = sectionInfo.title;
    self.disclosureButton.selected = !sectionInfo.isOpen;
}

- (void)toggle:(id)sender
{
    _sectionInfo.isOpen = !_sectionInfo.isOpen;
    self.disclosureButton.selected = !_sectionInfo.isOpen;
    
    if ([self.delegate respondsToSelector:@selector(sectionHeaderViewChanged:)]) {
        [self.delegate sectionHeaderViewChanged:self];
    }
}

- (void)setupContraints
{
    ////////// DISCLOSURE BUTTON ///////////
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.disclosureButton
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1.0
                                                                    constant:-5.0];
    [self addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.disclosureButton
                                              attribute:NSLayoutAttributeCenterY
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                              attribute:NSLayoutAttributeCenterY
                                             multiplier:1.0
                                               constant:0.0];
    [self addConstraint:constraint];
    
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

+ (NSString*) reuseIdentifier {
    return NSStringFromClass([self class]);
}

@end
