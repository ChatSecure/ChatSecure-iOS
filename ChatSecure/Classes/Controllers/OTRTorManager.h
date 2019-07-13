//
//  OTRTorManager.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 10/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import Tor;

NS_ASSUME_NONNULL_BEGIN
@interface OTRTorManager : NSObject

//@property (nonatomic, strong) CPAProxyManager *torManager;
@property (nonatomic, strong, readonly) TORController *torController;

@property (nonatomic, class, readonly) OTRTorManager *shared;

@property (nonatomic, class, readonly) NSString *SOCKSHost;
@property (nonatomic, class, readonly) uint16_t SOCKSPort;

+ (instancetype) sharedInstance;

@end
NS_ASSUME_NONNULL_END
