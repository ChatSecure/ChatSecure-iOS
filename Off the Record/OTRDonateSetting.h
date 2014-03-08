//
//  OTRDonateSetting.h
//  Off the Record
//
//  Created by Christopher Ballinger on 2/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRSetting.h"

@class OTRDonateSetting;

@protocol OTRDonateSettingDelegate <OTRSettingDelegate>
- (void) donateSettingPressed:(OTRDonateSetting*)setting;
@end

@interface OTRDonateSetting : OTRSetting

@property (nonatomic, weak) id<OTRDonateSettingDelegate> delegate;

@end
