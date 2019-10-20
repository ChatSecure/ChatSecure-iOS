//
//  OTRLockButton.m
//  Off the Record
//
//  Created by David Chiles on 2/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRLockButton.h"
@import OTRAssets;

static NSString *const kOTRLockImageName            = @"Lock_Locked";
static NSString *const kOTRLockAndVerifiedImageName = @"Lock_Locked_Verified";
static NSString *const kOTRLockedAndErrorImageName  = @"Lock_Locked_red";
static NSString *const kOTRLockedAndWarnImageName   = @"Lock_Locked_yellow";
static NSString *const kOTRUnlockImageName          = @"Lock_Unlocked";

typedef void (^ButtonBlock)(id sender);

@interface OTRLockButton ()

@property (nonatomic, strong) ButtonBlock blockAction;

@end


@implementation OTRLockButton

- (void)setLockStatus:(OTRLockStatus)lockStatus
{
    UIImage * backgroundImage = nil;
    
    switch (lockStatus) {
        case OTRLockStatusUnlocked:
            backgroundImage = [UIImage imageNamed:kOTRUnlockImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
            break;
        case OTRLockStatusLockedAndVerified:
            backgroundImage = [UIImage imageNamed:kOTRLockAndVerifiedImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
            break;
        case OTRLockStatusLockedAndError:
            backgroundImage = [UIImage imageNamed:kOTRLockedAndErrorImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
            break;
        case OTRLockStatusLockedAndWarn:
            backgroundImage = [UIImage imageNamed:kOTRLockedAndWarnImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
            break;
        case OTRLockStatusLocked:
            backgroundImage = [UIImage imageNamed:kOTRLockImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
            break;
        default:
            backgroundImage = [UIImage imageNamed:kOTRUnlockImageName inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil];
            break;
    }
    
    CGRect buttonFrame = [self frame];
    
    buttonFrame.size.width = backgroundImage.size.width;
    buttonFrame.size.height = backgroundImage.size.height;
    [self setFrame:buttonFrame];
    
    [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(lockStatus))];
    _lockStatus = lockStatus;
    [self didChangeValueForKey:NSStringFromSelector(@selector(lockStatus))];
}

#pragma - MARK block handler

-(void) handleControlEvent:(UIControlEvents)event
                 withBlock:(ButtonBlock) block
{
    self.blockAction = block;
    [self addTarget:self action:@selector(callBlock:) forControlEvents:event];
}

-(void) callBlock:(id)sender{
    if (self.blockAction) {
        self.blockAction(sender);
    }
}

+(instancetype)lockButtonWithInitailLockStatus:(OTRLockStatus)lockStatus withBlock:(void(^)(OTRLockStatus currentStatus))block
{
    OTRLockButton * lockButton = [self buttonWithType:UIButtonTypeCustom];
    lockButton.lockStatus = lockStatus;
    
    [lockButton handleControlEvent:UIControlEventTouchUpInside withBlock:^(id sender) {
        if (block) {
            OTRLockStatus status = OTRLockStatusUnknown;
            if ([sender isKindOfClass:[OTRLockButton class]]) {
                status = ((OTRLockButton *)sender).lockStatus;
            }
            
            block(status);
        }
    }];
    return lockButton;
}
@end
