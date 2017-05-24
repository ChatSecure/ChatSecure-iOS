//
//  OTRDownloadMessage.m
//  ChatSecure
//
//  Created by Chris Ballinger on 5/24/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

@import YapDatabase;
#import "OTRLog.h"
#import "OTRDownloadMessage.h"
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
