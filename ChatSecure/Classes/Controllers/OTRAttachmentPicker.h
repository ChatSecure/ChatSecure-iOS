//
//  OTRAttachmentPicker.h
//  ChatSecure
//
//  Created by David Chiles on 1/16/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import UIKit;
@class OTRAttachmentPicker;

@protocol OTRAttachmentPickerDelegate <NSObject>

@required

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info;
- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker gotVideoURL:(NSURL *)videoURL;

@optional

- (void)attachmentPicker:(OTRAttachmentPicker *)attachmentPicker addAdditionalOptions:(UIAlertController *)alertController;

@end

@interface OTRAttachmentPicker : NSObject <UIImagePickerControllerDelegate>

@property (nonatomic, weak, readonly) UIViewController<UIPopoverPresentationControllerDelegate> *parentViewController;
@property (nonatomic, weak, readonly) id<OTRAttachmentPickerDelegate> delegate;

- (instancetype)initWithParentViewController:(UIViewController<UIPopoverPresentationControllerDelegate> *)parentViewController delegate:(id<OTRAttachmentPickerDelegate>)delegate;

- (void)showAlertControllerWithCompletion:(void (^)(void))completion;


@end
