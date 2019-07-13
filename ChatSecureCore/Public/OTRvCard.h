//
//  OTRvCard.h
//  ChatSecure
//
//  Created by Chris Ballinger on 7/1/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

@import Foundation;
@class XMPPvCardTemp;
#import "OTRYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN
@protocol OTRvCard <OTRYapDatabaseObjectProtocol>
@required
@property (nonatomic, strong, nullable) XMPPvCardTemp *vCardTemp;
@property (nonatomic, strong, nullable) NSDate *lastUpdatedvCardTemp;
@property (nonatomic) BOOL waitingForvCardTempFetch;
@property (nonatomic, strong, nullable) NSString *photoHash;
@property (nonatomic, strong, nullable) NSData *avatarData;
@end
NS_ASSUME_NONNULL_END
