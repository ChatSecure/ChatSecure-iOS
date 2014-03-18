//
//  OTRLockButton.m
//  Off the Record
//
//  Created by David Chiles on 2/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRLockButton.h"
#import "UIControl+JTTargetActionBlock.h"


static NSString *const kOTRLockImageName            = @"Lock_Locked";
static NSString *const kOTRLockAndVerifiedImageName = @"Lock_Locked_Verified";
static NSString *const kOTRLockedAndErrorImageName  = @"Lock_Locked_red";
static NSString *const kOTRLockedAndWarnImageName   = @"Lock_Locked_yellow";
static NSString *const kOTRUnlockImageName          = @"Lock_Unlocked";



@implementation OTRLockButton

- (void)setLockStatus:(OTRLockStatus)lockStatus
{
    UIImage * backgroundImage = nil;
    
    switch (lockStatus) {
        case OTRLockStatusUnlocked:
            backgroundImage = [UIImage imageNamed:kOTRUnlockImageName];
            break;
        case OTRLockStatusLockedAndVerified:
            backgroundImage = [UIImage imageNamed:kOTRLockAndVerifiedImageName];
            break;
        case OTRLockStatusLockedAndError:
            backgroundImage = [UIImage imageNamed:kOTRLockedAndErrorImageName];
            break;
        case OTRLockStatusLockedAndWarn:
            backgroundImage = [UIImage imageNamed:kOTRLockedAndWarnImageName];
            break;
        case OTRLockStatusLocked:
            backgroundImage = [UIImage imageNamed:kOTRLockImageName];
            break;
        default:
            backgroundImage = [UIImage imageNamed:kOTRUnlockImageName];
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

+(instancetype)lockButtonWithInitailLockStatus:(OTRLockStatus)lockStatus withBlock:(void(^)(OTRLockStatus currentStatus))block
{
    OTRLockButton * lockButton = [self buttonWithType:UIButtonTypeCustom];
    lockButton.lockStatus = lockStatus;
    [lockButton addEventHandler:^(id sender, UIEvent *event) {
        if (block) {
            OTRLockStatus status = OTRLockStatusUnknown;
            if ([sender isKindOfClass:[OTRLockButton class]]) {
                status = ((OTRLockButton *)sender).lockStatus;
            }
        
            block(status);
        }
    } forControlEvent:UIControlEventTouchUpInside];
    return lockButton;
}
@end
