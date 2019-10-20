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
@import ZXingObjC;
@import PureLayout;
#import  <QuartzCore/CALayer.h>

@import OTRAssets;

@interface OTRQRCodeViewController()
@property (nonatomic, assign) BOOL didSetupConstraints;
@end

@implementation OTRQRCodeViewController

- (instancetype) initWithQRString:(NSString*)qrString {
    if (self = [super init]) {
        _qrString = qrString;
        self.title = QR_CODE_STRING();
    }
    return self;
}

- (UIImage*)imageForQRString:(NSString*)qrString size:(CGSize)size {
    if (!qrString) {
        return nil;
    }
    ZXMultiFormatWriter *writer = [[ZXMultiFormatWriter alloc] init];
    ZXBitMatrix *result = [writer encode:qrString
                                  format:kBarcodeFormatQRCode
                                   width:size.width
                                  height:size.height
                                   error:nil];
    if (result) {
        ZXImage *image = [ZXImage imageWithMatrix:result];
        return [UIImage imageWithCGImage:image.cgimage];
    } else {
        return nil;
    }
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc] initForAutoLayout];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.layer.magnificationFilter = kCAFilterNearest;
    self.imageView.layer.shouldRasterize = YES;
    [self.view addSubview:self.imageView];
    
    self.instructionsLabel = [[UILabel alloc] initForAutoLayout];
    self.instructionsLabel.text = self.qrString;
    self.instructionsLabel.numberOfLines = 3;
    self.instructionsLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.instructionsLabel];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:DONE_STRING() style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonPressed:)];
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints {
    if (!self.didSetupConstraints) {
        CGFloat padding = 10;
        [self.imageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:padding];
        [self.imageView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:padding];
        [self.imageView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:padding];
        [self.imageView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.instructionsLabel withOffset:padding];
        
        [self.instructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:padding];
        [self.instructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:padding];
        [self.instructionsLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:padding];
        
        self.didSetupConstraints = YES;
    }
    [super updateViewConstraints];
}

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    
    UIImage *image = [self imageForQRString:self.qrString size:self.imageView.frame.size];
    self.imageView.image = image;
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void) doneButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didDismissQRCodeViewController:)]) {
        [self.delegate didDismissQRCodeViewController:self];
    } else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
