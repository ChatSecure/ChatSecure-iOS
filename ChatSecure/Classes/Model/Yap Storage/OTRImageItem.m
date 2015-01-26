//
//  OTRImageItem.m
//  ChatSecure
//
//  Created by David Chiles on 1/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRImageItem.h"

@implementation OTRImageItem

- (CGSize)mediaViewDisplaySize
{
    if (self.height && self.width) {
        return [[self class] normalizeWidth:self.width height:self.height];
    }
    return [super mediaViewDisplaySize];
}

@end
