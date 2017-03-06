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

@protocol OTRvCard <OTRYapDatabaseObjectProtocol>

@property (nonatomic, strong) XMPPvCardTemp *vCardTemp;
@property (nonatomic, strong) NSDate *lastUpdatedvCardTemp;
@property (nonatomic) BOOL waitingForvCardTempFetch;
@property (nonatomic, strong) NSString *photoHash;

@end
