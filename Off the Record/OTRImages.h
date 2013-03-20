//
//  OTRstatusImage.h
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRConstants.h"

@interface OTRStatusImage : NSObject


+(UIImage *)statusImageWithStatus:(OTRBuddyStatus)status;

@end
