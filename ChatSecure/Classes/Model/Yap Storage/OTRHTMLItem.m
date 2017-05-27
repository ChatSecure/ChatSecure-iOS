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
#import "OTRLog.h"

@interface OTRHTMLMetadata : NSObject
@property (nonatomic, strong, nullable) NSString *title;
@end
@implementation OTRHTMLMetadata
@end

@interface OTRHTMLItem ()
@property (nonatomic, class, readonly) NSCache *htmlCache;
@end

@implementation OTRHTMLItem

- (BOOL) shouldFetchMediaData {
    return ![[[self class] htmlCache] objectForKey:self.uniqueId];
}

// Return empty view for now
- (UIView *)mediaView {
    OTRHTMLMetadata *metadata = [[[self class] htmlCache] objectForKey:self.uniqueId];
    if (!metadata) {
        [self fetchMediaData];
        return nil;
    }
    CGSize size = [self mediaViewDisplaySize];
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    UILabel *textLabel = [[UILabel alloc] initWithFrame:frame];
    textLabel.numberOfLines = 0;
    textLabel.adjustsFontSizeToFitWidth = YES;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view addSubview:textLabel];
    textLabel.text = metadata.title;
    return view;
}

/** Overrideable in subclasses. This is called after data is fetched from db, but before display */
- (BOOL) handleMediaData:(NSData*)mediaData {
    HTMLDocument *html = [HTMLDocument documentWithData:mediaData
                                      contentTypeHeader:self.mimeType];
    NSString *title = [[html.rootElement firstNodeMatchingSelector:@"head"] firstNodeMatchingSelector:@"title"].textContent;
    if (!title) {
        return NO;
    }
    OTRHTMLMetadata *metadata = [[OTRHTMLMetadata alloc] init];
    metadata.title = title;
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
