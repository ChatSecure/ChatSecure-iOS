//
//  OTRSettingDetailViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/24/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import "OTRSettingDetailViewController.h"
#import "OTRSetting.h"
@import OTRAssets;

@interface OTRSettingDetailViewController()
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@end


@implementation OTRSettingDetailViewController
@synthesize otrSetting, saveButton, cancelButton;

- (void) dealloc {
    self.saveButton = nil;
    self.otrSetting = nil;
    self.cancelButton = nil;
}

- (id) init {
    if (self = [super init]) {
        self.saveButton = [[UIBarButtonItem alloc] initWithTitle:SAVE_STRING() style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
        self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING() style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CGSize) textSizeForLabel:(UILabel*)label {
    return [label.text sizeWithAttributes:
            @{NSFontAttributeName:label.font}];
}

@end
