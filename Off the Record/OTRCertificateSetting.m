//
//  OTRCertificateSetting.m
//  Off the Record
//
//  Created by David Chiles on 12/9/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCertificateSetting.h"
#import "OTRCertificateDomainViewController.h"

@implementation OTRCertificateSetting

- (id)initWithTitle:(NSString *)newTitle description:(NSString *)newDescription {
    self = [super initWithTitle:newTitle description:newDescription viewControllerClass:[OTRCertificateDomainViewController class]];
    return self;
}

@end
