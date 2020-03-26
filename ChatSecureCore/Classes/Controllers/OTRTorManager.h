//
//  OTRTorManager.h
//  ChatSecure
//
//  Created by Christopher Ballinger on 10/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import Foundation;
@class CPAProxyManager;

NS_ASSUME_NONNULL_BEGIN
@interface OTRTorManager : NSObject

@property (nonatomic, strong, nullable) CPAProxyManager *torManager;

+ (instancetype) sharedInstance;

@end
NS_ASSUME_NONNULL_END
