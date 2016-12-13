//
//  OTRGlobalState.h
//  ChatSecure
//
//  Created by Chris Ballinger on 12/11/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol OTRActiveThreadDelegate <NSObject>
@required
- (nullable NSString *)activeThreadYapKey;
@end

@interface OTRGlobalState : NSObject

@property (nonatomic, weak, readwrite, nullable) id<OTRActiveThreadDelegate> activeThreadDelegate;

+ (nonnull instancetype) sharedInstance;

@end
