//
//  OTRImagePicker.h
//  ChatSecure
//
//  Created by David Chiles on 1/16/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
@class OTRAttachmentPicker;

@protocol OTRAttachmentPickerDelegate <NSObject>

@required

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info;

@end

@interface OTRAttachmentPicker : NSObject <UIImagePickerControllerDelegate>

@property (nonatomic, weak, readonly) UIViewController *rootViewController;
@property (nonatomic, weak, readonly) id<OTRAttachmentPickerDelegate> delegate;

- (instancetype)initWithRootViewController:(UIViewController *)viewController delegate:(id<OTRAttachmentPickerDelegate>)delegate;

- (void)showAlertControllerWithCompletion:(void (^)(void))completion;


@end
