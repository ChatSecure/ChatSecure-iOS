//
//  OTRMediaItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/19/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"
#import "OTRImages.h"
@import JSQMessagesViewController;
@import YapDatabase;
#import "OTRDatabaseManager.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@implementation OTRMediaItem

- (instancetype) init {
    if (self = [super init]) {
        self.transferProgress = 0;
    }
    return self;
}

- (void)touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageMediaEdgeName];
    [[transaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction touchObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
    }];
}

- (void)touchParentMessage
{
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self touchParentMessageWithTransaction:transaction];
    }];
}

- (OTRBaseMessage *)parentMessageInTransaction:(YapDatabaseReadTransaction *)readTransaction
{
    __block OTRBaseMessage *message = nil;
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameMessageMediaEdgeName];
    [[readTransaction ext:extensionName] enumerateEdgesWithName:edgeName destinationKey:self.uniqueId collection:[[self class] collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        message = [OTRBaseMessage fetchObjectWithUniqueID:edge.sourceKey transaction:readTransaction];
        *stop = YES;
    }];
    return message;
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
