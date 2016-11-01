//
//  OTRUserInfoProfile.h
//  ChatSecure
//
//  Created by Chris Ballinger on 10/31/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol OTRUserInfoProfile <NSObject>
@required
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) UIImage *avatarImage;
@end
NS_ASSUME_NONNULL_END
