//
//  OTRSettingDetailViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingDetailViewController.h"
#import "Strings.h"

@implementation OTRSettingDetailViewController
@synthesize otrSetting, saveButton, cancelButton;

- (void) dealloc {
    self.saveButton = nil;
    self.otrSetting = nil;
    self.cancelButton = nil;
}

- (id) init {
    if (self = [super init]) {
        self.saveButton = [[UIBarButtonItem alloc] initWithTitle:SAVE_STRING style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
        self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
    }
    return self;
}

- (void) loadView {
    [super loadView];
    self.title = self.otrSetting.title;
    self.navigationItem.rightBarButtonItem = saveButton;
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void) save:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

@end
