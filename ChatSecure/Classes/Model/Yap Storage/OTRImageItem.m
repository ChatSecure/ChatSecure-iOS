//
//  OTRImageItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRImageItem.h"
#import "OTRImages.h"
#import "OTRMediaFileManager.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "OTRDatabaseManager.h"
#import "OTRMessage.h"


@implementation OTRImageItem

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
        __block NSString *buddyUniqueId = nil;
        [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            OTRMessage *message = [strongSelf parentMessageInTransaction:transaction];
            buddyUniqueId = [message buddyUniqueId];
        } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionBlock:^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [[OTRMediaFileManager sharedInstance] dataForItem:strongSelf buddyUniqueId:buddyUniqueId completion:^(NSData *data, NSError *error) {
                if([data length]) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    UIImage *image = [UIImage imageWithData:data];
                    [OTRImages setImage:image forIdentifier:strongSelf.uniqueId];
                    [strongSelf touchParentMessage];
                }
            } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        }];
        
    }
    return view;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
