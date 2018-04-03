//
//  OTRShareSetting.m
//  Off the Record
//
//  Created by David on 11/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRShareSetting.h"
@import OTRAssets;
#import "OTRAppDelegate.h"
#import "OTRQRCodeViewController.h"
#import "OTRUtilities.h"
#import "OTRActivityItemProvider.h"
#import "OTRQRCodeActivity.h"
#import "OTRConstants.h"

@implementation OTRShareSetting
@synthesize delegate = _delegate;

-(id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription
{
    self = [super initWithTitle:newTitle description:newDescription];
    if (self) {
        __weak typeof(self)weakSelf = self;
        self.actionBlock = ^void(id sender){
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf showActionSheet];
        };
    }
    return self;
}

-(void)showActionSheet
{
    if ([self.delegate respondsToSelector:@selector(didSelectShareSetting:)]) {
        [self.delegate didSelectShareSetting:self];
    }
}

@end
