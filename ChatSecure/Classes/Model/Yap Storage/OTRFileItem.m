//
//  OTRFileItem.m
//  ChatSecure
//
//  Created by Chris Ballinger on 5/19/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRFileItem.h"
#import "OTRMediaItem+Private.h"


@implementation OTRFileItem

// Return empty view for now
- (UIView *)mediaView {
    UIView *errorView = [self errorView];
    if (errorView) { return errorView; }
    CGSize size = [self mediaViewDisplaySize];
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    return [[UIView alloc] initWithFrame:frame];
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}

@end
