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
#import "ChatSecureCoreCompat-Swift.h"

@interface OTRDirectDownloadMessage()
@property (nonatomic, strong, readonly) NSString *parentMessageKey;
@property (nonatomic, strong, readonly) NSString *parentMessageCollection;
@end

@implementation OTRDirectDownloadMessage
@synthesize url = _url;

+ (id<OTRDownloadMessage>) downloadWithParentMessage:(id<OTRMessageProtocol>)parentMessage url:(nonnull NSURL *)url {
    return [[OTRDirectDownloadMessage alloc] initWithParentMessage:parentMessage url:url];
}

- (instancetype) initWithParentMessage:(id<OTRMessageProtocol>)parentMessage
                                   url:(NSURL*)url {
    NSParameterAssert(parentMessage);
    if (self = [super init]) {
        _parentMessageKey = parentMessage.messageKey;
        _parentMessageCollection = parentMessage.messageCollection;
        _url = url;
        self.text = url.absoluteString;
        self.messageSecurityInfo = [[OTRMessageEncryptionInfo alloc] initWithMessageSecurity:parentMessage.messageSecurity];
        self.date = parentMessage.messageDate;
        self.buddyUniqueId = parentMessage.threadId;
    }
    return self;
}

- (NSString*) threadCollection {
    // This is a hack to support group messages
    if ([self.parentObjectCollection isEqualToString:[OTRXMPPRoomMessage collection]]) {
        return [OTRXMPPRoom collection];
    } else {
        return [super threadCollection];
    }
}

- (nullable NSArray<YapDatabaseRelationshipEdge *> *)yapDatabaseRelationshipEdges {
    NSMutableArray *edges = [NSMutableArray arrayWithCapacity:3];
    NSArray *superEdges = [super yapDatabaseRelationshipEdges];
    if (superEdges) {
        [edges addObjectsFromArray:superEdges];
    }
    
    if (self.parentMessageKey) {
        NSString *edgeName = [YapDatabaseConstants edgeName:RelationshipEdgeNameDownload];
        YapDatabaseRelationshipEdge *parentEdge = [YapDatabaseRelationshipEdge edgeWithName:edgeName
                                                                            destinationKey:self.parentMessageKey
                                                                                collection:self.parentMessageCollection
                                                                           nodeDeleteRules:YDB_NotifyIfSourceDeleted | YDB_NotifyIfDestinationDeleted];
        [edges addObject:parentEdge];
    }
    return edges;
}

- (nullable id) parentObjectWithTransaction:(YapDatabaseReadTransaction*)transaction {
    if (!self.parentObjectKey || !self.parentObjectCollection) {
        return nil;
    }
    id parent = [transaction objectForKey:self.parentObjectKey inCollection:self.parentObjectCollection];
    return parent;
}

- (void) touchParentObjectWithTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    if (!self.parentObjectKey || !self.parentObjectCollection) {
        return;
    }
    [transaction touchObjectForKey:self.parentObjectKey inCollection:self.parentObjectCollection];
}


- (nullable id<OTRMessageProtocol>) parentMessageWithTransaction:(YapDatabaseReadTransaction*)transaction {
    NSParameterAssert(transaction);
    if (!transaction) { return nil; }
    id object = [self parentObjectWithTransaction:transaction];
    if ([object conformsToProtocol:@protocol(OTRMessageProtocol)]) {
        return object;
    }
    return nil;
}

- (void) touchParentMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    NSParameterAssert(transaction);
    if (!transaction) { return; }
    id<OTRMessageProtocol> message = [self parentMessageWithTransaction:transaction];
    if (!message) { return; }
    [message touchWithTransaction:transaction];
}

- (NSString*) parentObjectKey {
    return _parentMessageKey;
}

- (void) setParentObjectKey:(NSString *)parentObjectKey {
    _parentMessageKey = parentObjectKey;
}

- (NSString*) parentObjectCollection {
    return _parentMessageCollection;
}

- (void) setParentObjectCollection:(NSString *)parentObjectCollection {
    _parentMessageCollection = parentObjectCollection;
}

@end

@implementation UIAlertAction (OTRDownloadMessage)

+ (NSArray<UIAlertAction*>*) actionsForMediaMessage:(id<OTRMessageProtocol>)mediaMessage sourceView:(UIView*)sourceView viewController:(UIViewController*)viewController {
    NSParameterAssert(mediaMessage);
    NSParameterAssert(sourceView);
    NSParameterAssert(viewController);
    if (!mediaMessage || !sourceView || !viewController) { return @[]; }
    NSMutableArray<UIAlertAction*> *actions = [NSMutableArray new];
    
    NSString *mediaItemUniqueId = mediaMessage.messageMediaItemKey;
    NSString *messageText = mediaMessage.messageText;
    NSURL *url = nil;
    if (messageText.length) {
        NSURL *maybeURL = [NSURL URLWithString:messageText];
        // sometimes the scheme is aesgcm, which can't be shared normally
        if ([maybeURL.scheme isEqualToString:@"https"]) {
            url = maybeURL;
        }
    }
    
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:SHARE_STRING() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSMutableArray *activityItems = [NSMutableArray new];
        if (url) {
            [activityItems addObject:url];
        }
        // This is sorta janky, but only support fetching images for now
        if (mediaItemUniqueId.length) {
            UIImage *image = [OTRImages imageWithIdentifier:mediaItemUniqueId];
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
            UIPasteboard.generalPasteboard.URL = url;
        }];
        UIAlertAction *openInSafari = [UIAlertAction actionWithTitle:OPEN_IN_SAFARI() style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIApplication.sharedApplication open:url];
        }];
        [actions addObject:copyLinkAction];
        [actions addObject:openInSafari];
    }
    
    return actions;
}

@end

// Shim model for legacy database migration
@interface OTRDownloadMessage: MTLModel
@end

@implementation OTRDownloadMessage
- (id)initWithCoder:(NSCoder *)aDecoder
{
    return (OTRDownloadMessage*)[[OTRDirectDownloadMessage alloc] initWithCoder:aDecoder];
}
@end
