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
@import JSQMessagesViewController;
#import "OTRDatabaseManager.h"
#import "OTRIncomingMessage.h"
#import "OTROutgoingMessage.h"

@interface OTRImageItem()
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;
@end

@implementation OTRImageItem

- (instancetype) initWithFilename:(NSString *)filename size:(CGSize)size mimeType:(NSString *)mimeType isIncoming:(BOOL)isIncoming {
    if (self = [super initWithFilename:filename mimeType:mimeType isIncoming:isIncoming]) {
        self.size = size;
    }
    return self;
}

- (CGSize)mediaViewDisplaySize
{
    if (self.height && self.width) {
        return [[self class] normalizeWidth:self.width height:self.height];
    }
    return [super mediaViewDisplaySize];
}

- (CGSize) size {
    return CGSizeMake(self.width, self.height);
}

- (void) setSize:(CGSize)size {
    _width = size.width;
    _height = size.height;
}

- (UIView *)mediaView {
    UIView *view = [super mediaView];
    if (!view) {
        //async loading image into OTRImages image cache
        __weak typeof(self)weakSelf = self;
        __block NSString *buddyUniqueId = nil;
        [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            OTRBaseMessage *message = [strongSelf parentMessageInTransaction:transaction];
            buddyUniqueId = [message buddyUniqueId];
        } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionBlock:^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [[OTRMediaFileManager sharedInstance] dataForItem:strongSelf buddyUniqueId:buddyUniqueId completion:^(NSData *data, NSError *error) {
                if([data length]) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    UIImage *image = [UIImage imageWithData:data];
                    [OTRImages setImage:image forIdentifier:strongSelf.uniqueId];
                    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                        [strongSelf touchParentMessageWithTransaction:transaction];
                    }];
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
