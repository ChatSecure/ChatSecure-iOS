//
//  OTRHTMLItem.m
//  ChatSecure
//
//  Created by Chris Ballinger on 5/25/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRHTMLItem.h"
#import "OTRDatabaseManager.h"
@import PureLayout;
@import HTMLReader;
@import OTRAssets;
#import "OTRLog.h"
#import "OTRMediaItem+Private.h"
#import "ChatSecureCoreCompat-Swift.h"

@interface OTRHTMLMetadata : NSObject
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSURL *url;
@end
@implementation OTRHTMLMetadata
@end

@interface OTRHTMLItem ()
@property (nonatomic, class, readonly) NSCache *htmlCache;
@end

@implementation OTRHTMLItem

- (BOOL) shouldFetchMediaData {
    return !self.metadata;
}

- (CGSize)mediaViewDisplaySize
{
    return CGSizeMake(250.0f, 70.0f);
}

- (NSString*) displayText {
    NSString *text = self.metadata.url.absoluteString;
    if (!text.length) {
        [self fetchMediaData];
        text = self.filename;
    }
    return [NSString stringWithFormat:@"🔗 %@", text];
}

- (nullable OTRHTMLMetadata*) metadata {
    return [[[self class] htmlCache] objectForKey:self.uniqueId];
}

// Return empty view for now
- (UIView *)mediaView {
    UIView *errorView = [self errorView];
    if (errorView) { return errorView; }
    OTRHTMLMetadata *metadata = [self metadata];
    if (!metadata) {
        [self fetchMediaData];
        return nil;
    }
    HTMLPreviewView *view = [HTMLPreviewView otr_viewFromNib];
    if (!view) {
        return nil;
    }
    [view setURL:metadata.url title:metadata.title];
    CGSize size = [self mediaViewDisplaySize];
    view.frame = CGRectMake(0, 0, size.width, size.height);;
    view.backgroundColor = [UIColor jsq_messageBubbleLightGrayColor];
    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view isOutgoing:!self.isIncoming];
    return view;
}

/** Overrideable in subclasses. This is called after data is fetched from db, but before display */
- (BOOL) handleMediaData:(NSData*)mediaData message:(nonnull id<OTRMessageProtocol>)message {
    HTMLDocument *html = [HTMLDocument documentWithData:mediaData
                                      contentTypeHeader:self.mimeType];
    NSString *title = [[html.rootElement firstNodeMatchingSelector:@"head"] firstNodeMatchingSelector:@"title"].textContent;
    if (!title) {
        return NO;
    }
    OTRHTMLMetadata *metadata = [[OTRHTMLMetadata alloc] init];
    metadata.title = title;
    metadata.url = [NSURL URLWithString:message.messageText];
    [[[self class] htmlCache] setObject:metadata forKey:self.uniqueId];
    return YES;
}


+ (NSCache*) htmlCache {
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });
    return cache;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
