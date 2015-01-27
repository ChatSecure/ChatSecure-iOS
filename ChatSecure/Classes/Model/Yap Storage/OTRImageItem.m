//
//  OTRImageItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRImageItem.h"
#import "OTRImages.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"


@implementation OTRImageItem

- (NSString *)mediaPath
{
    // Example file storage in documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:self.filename];
}

- (CGSize)mediaViewDisplaySize
{
    if (self.height && self.width) {
        return [[self class] normalizeWidth:self.width height:self.height];
    }
    return [super mediaViewDisplaySize];
}

- (UIView *)mediaView {
    UIView *view = [super mediaView];
    if (!view) {
        //async loading image into OTRImages image cache
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            UIImage *image = [UIImage imageWithContentsOfFile:[strongSelf mediaPath]];
            [OTRImages setImage:image forIdentifier:strongSelf.filename];
            [strongSelf touchParentMessage];
        });
    }
    return view;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
