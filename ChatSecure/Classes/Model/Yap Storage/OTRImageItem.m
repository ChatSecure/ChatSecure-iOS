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
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"
#import "OTRMessage.h"

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
    UIImage *image = [OTRImages imageWithIdentifier:self.filename];
    if (image) {
        CGSize size = [self mediaViewDisplaySize];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:!self.isIncoming];
        return imageView;
    }
    else {
        //async loading image into OTRImages image cache
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            UIImage *image = [UIImage imageWithContentsOfFile:[strongSelf mediaPath]];
            [OTRImages setImage:image forIdentifier:strongSelf.filename];
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.media destinationKey:strongSelf.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
                    [transaction touchObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
                }];
            }];
        });
    }
    return nil;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
