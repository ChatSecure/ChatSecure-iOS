//
//  OTRLanguageListSettingViewController.m
//  Off the Record
//
//  Created by David on 11/20/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRLanguageListSettingViewController.h"
#import "OTRLanguageSetting.h"
@import OTRAssets;

@interface OTRLanguageListSettingViewController ()

@end

@implementation OTRLanguageListSettingViewController

- (void)viewDidLoad {
    //Need to regenerate list so that picks up on possible change in current locale since last generated
    if ([self.otrSetting isKindOfClass:[OTRLanguageSetting class]]) {
        [((OTRLanguageSetting *)self.otrSetting) generatePossibleValues];
    }
    [super viewDidLoad];
}

@end
