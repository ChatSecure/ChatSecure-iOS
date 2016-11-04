//
//  OTRLockButton.h
//  Off the Record
//
//  Created by David Chiles on 2/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, OTRLockStatus) {
    OTRLockStatusUnknown,
    OTRLockStatusLocked,
    OTRLockStatusLockedAndVerified,
    OTRLockStatusLockedAndWarn,
    OTRLockStatusLockedAndError,
    OTRLockStatusUnlocked,
    
};

@interface OTRLockButton : UIButton

@property (nonatomic) OTRLockStatus lockStatus;

+(instancetype)lockButtonWithInitailLockStatus:(OTRLockStatus)lockStatus withBlock:(void(^)(OTRLockStatus currentStatus))block;

@end
