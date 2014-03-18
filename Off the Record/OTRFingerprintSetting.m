//
//  OTRFingerprintSetting.m
//  Off the Record
//
//  Created by David Chiles on 2/11/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRFingerprintSetting.h"

#import "OTRFingerprintsViewController.h"

@implementation OTRFingerprintSetting

- (id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription {
    self = [super initWithTitle:newTitle description:newDescription viewControllerClass:[OTRFingerprintsViewController class]];
    return self;
}

@end
