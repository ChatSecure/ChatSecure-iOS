//
//  OTRQRCodeViewController.m
//  Off the Record
//
//  Created by Chris Ballinger on 5/7/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRQRCodeViewController.h"
#import "Strings.h"

@implementation OTRQRCodeViewController
@synthesize imageView;

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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:DONE_STRING style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonPressed:)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.imageView = nil;
}

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    CGFloat width = 300;
    self.imageView.frame = CGRectMake(10, self.view.frame.size.height/2 - width/2, width, width);
}

- (void) doneButtonPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
