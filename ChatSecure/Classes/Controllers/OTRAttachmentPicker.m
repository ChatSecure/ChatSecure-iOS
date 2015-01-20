//
//  OTRImagePicker.m
//  ChatSecure
//
//  Created by David Chiles on 1/16/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRAttachmentPicker.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "Strings.h"

@interface OTRAttachmentPicker () <UINavigationControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end

@implementation OTRAttachmentPicker

- (instancetype)initWithRootViewController:(UIViewController *)viewController delegate:(id<OTRAttachmentPickerDelegate>)delegate
{
    if (self = [self init]) {
        _rootViewController = viewController;
        _delegate = delegate;
    }
    return self;
}

- (void)showAlertControllerWithCompletion:(void (^)(void))completion
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertAction *takePhotoAction = [UIAlertAction actionWithTitle:TAKE_PHOTO_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        }];
        [alertController addAction:takePhotoAction];
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIAlertAction *openLibraryAction = [UIAlertAction actionWithTitle:PHOTO_LIBRARY_STRING style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }];
        [alertController addAction:openLibraryAction];
    }
    
    UIAlertAction *cancelAlertAction = [UIAlertAction actionWithTitle:CANCEL_STRING style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:cancelAlertAction];
    
    [self.rootViewController presentViewController:alertController animated:YES completion:completion];
    
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    self.imagePickerController = imagePickerController;
    [self.rootViewController presentViewController:self.imagePickerController animated:YES completion:nil];
}

#pragma - mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    NSString *imageString = (NSString *)kUTTypeImage;
    
    if ([mediaType isEqualToString:imageString]) {
        UIImage *editedImage = (UIImage *)info[UIImagePickerControllerEditedImage];
        UIImage *originalImage = (UIImage *)info[UIImagePickerControllerOriginalImage];
        UIImage *finalImage = nil;
        
        if (editedImage) {
            finalImage = editedImage;
        }
        else if (originalImage) {
            finalImage = originalImage;
        }
        
        if ([self.delegate respondsToSelector:@selector(attachmentPicker:gotPhoto:withInfo:)]) {
            [self.delegate attachmentPicker:self gotPhoto:finalImage withInfo:info];
        }
        
        [picker dismissViewControllerAnimated:YES completion:nil];
        self.imagePickerController = nil;
    }
}

 #pragma - mark UINavigatoinControllerDelegate Methods

-(void)navigationController:(UINavigationController *)navigationController
     willShowViewController:(UIViewController *)viewController
                   animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

@end
