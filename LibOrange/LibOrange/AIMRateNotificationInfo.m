//
//  AIMRateNotificationInfo.m
//  LibOrange
//
//  Created by Alex Nichol on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMRateNotificationInfo.h"


@implementation AIMRateNotificationInfo

@synthesize rateClass;
@synthesize alertReason;

- (id)initWithClass:(AIMRateClassType)classType reason:(AIMRateAlertType)reason {
	if ((self = [super init])) {
		rateClass = classType;
		alertReason = reason;
	}
	return self;
}

+ (AIMRateNotificationInfo *)notificationInfoWithClass:(AIMRateClassType)classType reason:(AIMRateAlertType)reason {
	return [[[AIMRateNotificationInfo alloc] initWithClass:classType reason:reason] autorelease];
}

@end
