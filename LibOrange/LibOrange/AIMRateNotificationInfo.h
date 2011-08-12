//
//  AIMRateNotificationInfo.h
//  LibOrange
//
//  Created by Alex Nichol on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	AIMRateClassTypeSnacs,
	AIMRateClassTypeOther
} AIMRateClassType;

typedef enum {
	AIMRateAlertTypeWarning,
	AIMRateAlertTypeLimit,
	AIMRateAlertTypeClear,
	AIMRateAlertTypeOther
} AIMRateAlertType;

@interface AIMRateNotificationInfo : NSObject {
    AIMRateClassType rateClass;
	AIMRateAlertType alertReason;
}

@property (readonly) AIMRateClassType rateClass;
@property (readonly) AIMRateAlertType alertReason;

- (id)initWithClass:(AIMRateClassType)classType reason:(AIMRateAlertType)reason;
+ (AIMRateNotificationInfo *)notificationInfoWithClass:(AIMRateClassType)classType reason:(AIMRateAlertType)reason;

@end
