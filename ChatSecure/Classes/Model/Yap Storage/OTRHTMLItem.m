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

// Return empty view for now
- (UIView *)mediaView {
    CGSize size = [self mediaViewDisplaySize];
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    UILabel *textLabel = [[UILabel alloc] initWithFrame:frame];
    textLabel.numberOfLines = 0;
    textLabel.adjustsFontSizeToFitWidth = YES;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view addSubview:textLabel];
    
    OTRHTMLMetadata *metadata = [[[self class] htmlCache] objectForKey:self.uniqueId];
    if (metadata) {
        textLabel.text = metadata.title;
        return view;
    }

    //async loading image into OTRImages image cache
    __weak typeof(self)weakSelf = self;
    __block NSString *buddyUniqueId = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        OTRBaseMessage *message = [strongSelf parentMessageInTransaction:transaction];
        buddyUniqueId = [message buddyUniqueId];
    } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionBlock:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (!buddyUniqueId) {
            DDLogError(@"Message/buddy not found");
            return;
        }
        [[OTRMediaFileManager sharedInstance] dataForItem:strongSelf buddyUniqueId:buddyUniqueId completion:^(NSData *data, NSError *error) {
            if (!data.length) {
                return;
            }
            __strong typeof(weakSelf)strongSelf = weakSelf;
            HTMLDocument *html = [HTMLDocument documentWithData:data
                                              contentTypeHeader:strongSelf.mimeType];
            NSString *title = [[html.rootElement firstNodeMatchingSelector:@"head"] firstNodeMatchingSelector:@"title"].textContent;
            OTRHTMLMetadata *metadata = [[OTRHTMLMetadata alloc] init];
            metadata.title = title;
            [[[self class] htmlCache] setObject:metadata forKey:strongSelf.uniqueId];
            [OTRDatabaseManager.shared.readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                [strongSelf touchParentMessageWithTransaction:transaction];
            }];
        } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }];
    return nil;
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
