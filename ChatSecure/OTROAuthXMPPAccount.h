//
//  OTROAuthXMPPAccount.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPAccount.h"

@interface OTROAuthXMPPAccount : OTRXMPPAccount

@property (nonatomic, strong) NSDictionary *oAuthTokenDictionary;
@property (nonatomic, strong) id accountSpecificToken;

@end
