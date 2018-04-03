//
//  OTRDonateSetting.m
//  Off the Record
//
//  Created by Christopher Ballinger on 2/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRDonateSetting.h"
@import OTRAssets;

@implementation OTRDonateSetting
@synthesize delegate = _delegate;

-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription
{
    self = [super initWithTitle:newTitle description:newDescription];
    if (self) {
        __weak typeof (self) weakSelf = self;
        self.actionBlock = ^void(id sender){
            [weakSelf openDonationDialog];
        };
    }
    return self;
}

- (void) openDonationDialog {
    if (self.delegate) {
        [self.delegate donateSettingPressed:self];
    }
}


@end
