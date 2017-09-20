//
//  OTRMediaItem+Private.h
//  ChatSecureCore
//
//  Created by Chris Ballinger on 6/14/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"
#import "OTRDownloadMessage.h"

@interface OTRMediaItem ()
/** Returns view to help assist in manually (re)downloading media, or nil if not needed */
- (nullable UIView*) errorView;
/** ⚠️ Do not call from within an existing database transaction */
- (nullable id<OTRDownloadMessage>) downloadMessage;
@end
