//
//  OTRQRCodeViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 5/7/12.
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

#import "OTRQRCodeViewController.h"
#import "Strings.h"

@implementation OTRQRCodeViewController
@synthesize imageView, instructionsLabel;

- (id) init 
{
    if (self = [super init]) 
    {
        self.title = @"QR Code";
    }
    return self;
}

- (void) loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatsecure_qrcode.png"]];
    [self.view addSubview:imageView];
    self.instructionsLabel = [[UILabel alloc] init];
    self.instructionsLabel.text = QR_CODE_INSTRUCTIONS_STRING;
    self.instructionsLabel.numberOfLines = 3;
    [self.view addSubview:instructionsLabel];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:DONE_STRING style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonPressed:)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.imageView = nil;
    self.instructionsLabel = nil;
}

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    CGFloat width = 300;
    self.imageView.frame = CGRectMake(self.view.frame.size.width/2 - width/2, 11, width, width);
    self.instructionsLabel.frame = CGRectMake(10, self.view.frame.size.height - 100, self.view.frame.size.width - 20, 100);
}

- (void) doneButtonPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
}

@end
