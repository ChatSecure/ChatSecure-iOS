//
//  OTRXMPPCreateViewController.h
//  Off the Record
//
//  Created by David Chiles on 12/20/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPLoginViewController.h"

@interface OTRXMPPCreateViewController : OTRXMPPLoginViewController


@property (nonatomic,strong) NSString * selectedHostname;

- (instancetype)initWithHostnames:(NSArray *)hostnames;
+ (instancetype)createViewControllerWithHostnames:(NSArray *)hostNames;

@end
