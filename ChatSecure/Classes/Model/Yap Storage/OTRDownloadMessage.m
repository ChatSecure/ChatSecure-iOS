//
//  OTRDownloadMessage.m
//  ChatSecure
//
//  Created by Chris Ballinger on 5/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@import YapDatabase;
@import OTRAssets;
#import "OTRLog.h"
#import "OTRImages.h"
#import "OTRDownloadMessage.h"
#import "UIActivity+ChatSecure.h"
#import <ChatSecureCore/ChatSecureCore-Swift.h>

@interface OTRDownloadMessage ()
- (instancetype) initWithParentMessage:(OTRBaseMessage*)parentMessage
                                   url:(NSURL*)url;
@end

@implementation OTRDownloadMessage

- (instancetype) initWithParentMessage:(OTRBaseMessage*)parentMessage
                                   url:(NSURL*)url {
    NSParameterAssert(parentMessage);
    if (self = [super init]) {
        _parentMessageId = parentMessage.uniqueId;
        _url = url;
        self.text = url.absoluteString;
        self.messageSecurityInfo = parentMessage.messageSecurityInfo;
        self.date = parentMessage.date;
        self.buddyUniqueId = parentMessage.buddyUniqueId;
    }
    return self;
}

- (nullable NSArray<YapDatabaseRelationshipEdge *> *)yapDatabaseRelationshipEdges {
    NSMutableArray *edges = [NSMutableArray arrayWithCapacity:3];
    NSArray *superEdges = [super yapDatabaseRelationshipEdges];
    if (superEdges) {
        [edges addObjectsFromArray:superEdges];
    }
    
    if (self.parentMessageId) {
        NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameDownload];
        YapDatabaseRelationshipEdge *parentEdge = [YapDatabaseRelationshipEdge edgeWithName:edgeName
                                                                            destinationKey:self.parentMessageId
                                                                                collection:[OTRBaseMessage collection]
                                                                           nodeDeleteRules:YDB_NotifyIfSourceDeleted | YDB_NotifyIfDestinationDeleted];
        [edges addObject:parentEdge];
    }
    return edges;
}

/**  If available, existing instances will be returned. */
+ (NSArray<OTRDownloadMessage*>*) existingDownloadsForMessage:(OTRBaseMessage*)message transaction:(YapDatabaseReadTransaction*)transaction {
    NSParameterAssert(message);
    if (!message) {
        return @[];
    }
    NSMutableArray<OTRDownloadMessage*> *downloadMessages = [NSMutableArray array];
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameDownload];
    YapDatabaseRelationshipTransaction *relationship = [transaction ext:extensionName];
    if (!relationship) {
        DDLogWarn(@"%@ not registered!", extensionName);
    }
    [relationship enumerateEdgesWithName:edgeName destinationKey:message.uniqueId collection:[OTRBaseMessage collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRDownloadMessage *download = [OTRDownloadMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (download) {
            [downloadMessages addObject:download];
        }
    }];
    return downloadMessages;
}

/** Returns an unsaved array of downloadable URLs. */
+ (NSArray<OTRDownloadMessage*>*) downloadsForMessage:(OTRBaseMessage*)message {
    NSParameterAssert(message);
    if (!message) {
        return @[];
    }
    NSMutableArray<OTRDownloadMessage*> *downloadMessages = [NSMutableArray array];
    [message.downloadableNSURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        OTRDownloadMessage *download = [[OTRDownloadMessage alloc] initWithParentMessage:message url:url];
        [downloadMessages addObject:download];
    }];
    return downloadMessages;
}

+ (BOOL) hasExistingDownloadsForMessage:(OTRBaseMessage*)message transaction:(YapDatabaseReadTransaction*)transaction {
    NSParameterAssert(message);
    if (!message) {
        return NO;
    }
    NSString *extensionName = [YapDatabaseConstants extensionName:DatabaseExtensionNameRelationshipExtensionName];
    NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameDownload];
    YapDatabaseRelationshipTransaction *relationship = [transaction ext:extensionName];
    if (!relationship) {
        DDLogWarn(@"%@ not registered!", extensionName);
    }
    NSUInteger count = [relationship edgeCountWithName:edgeName];
    return count > 0;
}

@end

@implementation UIAlertAction (OTRDownloadMessage)

+ (NSArray<UIAlertAction*>*) actionsForDownloadMessage:(OTRDownloadMessage*)downloadMessage sourceView:(UIView*)sourceView viewController:(UIViewController*)viewController {
    NSParameterAssert(downloadMessage);
    NSParameterAssert(sourceView);
    NSParameterAssert(viewController);
    if (!downloadMessage || !sourceView || !viewController) { return @[]; }
    NSMutableArray<UIAlertAction*> *actions = [NSMutableArray new];
    
    NSURL *url = nil;
    // sometimes the scheme is aesgcm, which can't be shared normally
    if ([downloadMessage.url.scheme isEqualToString:@"https"]) {
        url = downloadMessage.url;
    }
    
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:SHARE_STRING() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSMutableArray *activityItems = [NSMutableArray new];
        if (url) {
            [activityItems addObject:url];
        }
        // This is sorta janky, but only support fetching images for now
        if (downloadMessage.mediaItemUniqueId.length) {
            UIImage *image = [OTRImages imageWithIdentifier:downloadMessage.mediaItemUniqueId];
            if (image) {
                [activityItems addObject:image];
            }
        }
        NSArray<UIActivity*> *activities = UIActivity.otr_linkActivities;
        UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:activities];
        
        share.popoverPresentationController.sourceView = sourceView;
        share.popoverPresentationController.sourceRect = sourceView.bounds;
        [viewController presentViewController:share animated:YES completion:nil];
    }];
    [actions addObject:shareAction];
    
    if (url) {
        UIAlertAction *copyLinkAction = [UIAlertAction actionWithTitle:COPY_LINK_STRING() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIPasteboard.generalPasteboard.persistent = YES;
            UIPasteboard.generalPasteboard.URL = url;
        }];
        UIAlertAction *openInSafari = [UIAlertAction actionWithTitle:OPEN_IN_SAFARI() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIApplication.sharedApplication openURL:url];
        }];
        [actions addObject:copyLinkAction];
        [actions addObject:openInSafari];
    }
    
    return actions;
}

@end
