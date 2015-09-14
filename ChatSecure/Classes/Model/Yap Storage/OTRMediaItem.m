//
//  OTRMediaItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"
#import "OTRImages.h"
#import "JSQMessagesMediaPlaceholderView.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import "OTRMessage.h"

@implementation OTRMediaItem

- (instancetype) init {
    if (self = [super init]) {
        self.transferProgress = 0;
    }
    return self;
}

- (void)touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.media destinationKey:self.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction touchObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
    }];
}

- (void)touchParentMessage
{
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self touchParentMessageWithTransaction:transaction];
    }];
}

- (OTRMessage *)parentMessageInTransaction:(YapDatabaseReadTransaction *)readTransaction
{
    __block OTRMessage *message = nil;
    [[readTransaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.media destinationKey:self.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:readTransaction];
        *stop = YES;
    }];
    return message;
}

#pragma - mark JSQMessageMediaData Methods

- (NSUInteger)mediaHash
{
    return [self hash];
}

- (UIView *)mediaView
{
    UIImage *image = [OTRImages imageWithIdentifier:self.uniqueId];
    if (image) {
        CGSize size = [self mediaViewDisplaySize];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(0, 0, size.width, size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:imageView isOutgoing:!self.isIncoming];
        return imageView;
    }
    return nil;
}

- (CGSize)mediaViewDisplaySize
{
    //Taken from JSQMediaItem Example project
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return CGSizeMake(315.0f, 225.0f);
    }
    
    return CGSizeMake(210.0f, 150.0f);
}

- (UIView *)mediaPlaceholderView
{
    CGSize size = [self mediaViewDisplaySize];
    UIView *view = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
    view.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view isOutgoing:!self.isIncoming];
    return view;
}

- (NSUInteger)hash
{
    return self.filename.hash;
}

#pragma - mark YapDatabaseRelationshipNode Methods

- (id)yapDatabaseRelationshipEdgeDeleted:(YapDatabaseRelationshipEdge *)edge withReason:(YDB_NotifyReason)reason
{
    //TODO:Delete File because the parent OTRMessage was deleted
    return nil;
}

#pragma - mark Class Methods

+ (CGSize)normalizeWidth:(CGFloat)width height:(CGFloat)height
{
    CGFloat maxWidth = 210;
    CGFloat maxHeight = 150;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        maxWidth = 315;
        maxHeight = 225;
    }
    
    float aspectRatio = width / height;
    
    if (aspectRatio < 1) {
        //Taller then wider then use max height and resize width
        CGFloat newWidth = maxHeight * aspectRatio;
        return CGSizeMake(newWidth, maxHeight);
    }
    else {
        //Wider than taller then use max width and resize height
        CGFloat newHeight = maxWidth * 1/aspectRatio;
        return CGSizeMake(maxWidth, newHeight);
    }
}

@end
