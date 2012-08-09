//
//  Crittercism.h
//  Crittercism-iOS
//
//  Created by Alvin Liang on 2/14/12.
//  Copyright (c) 2012 Crittercism. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CrittercismJSONKit.h"
#import <QuartzCore/QuartzCore.h>
#import "CrittercismReachability.h"
//#import "<CoreLocation/CoreLocation.h>"

@protocol CrittercismDelegate <NSObject>

@optional
-(void) crittercismDidClose;
-(void) crittercismDidCrashOnLastLoad;
@end

@interface Crittercism : NSObject {
	NSMutableData *responseData;
	CFMutableDictionaryRef *connectionToInfoMapping;
	id <CrittercismDelegate> delegate;
    BOOL didCrashOnLastLoad;
}

@property(retain) id <CrittercismDelegate> delegate;
@property(assign) BOOL didCrashOnLastLoad;

+ (Crittercism*)sharedInstance;
+ (void) initWithAppID:(NSString *)_app_id andKey:(NSString *)_keyStr andSecret:(NSString *)_secretStr;
+ (NSString *) getAppID;
+ (NSString *) getKey;
+ (NSString *) getSecret;
+ (void) configurePushNotification:(NSData *) deviceToken;
+ (void) setAge:(int)age;
+ (void) setGender:(NSString *)gender;
+ (void) setUsername:(NSString *)username;
+ (void) setEmail:(NSString *)email;
+ (void) setValue:(NSString *)value forKey:(NSString *)key;
+ (int) getCurrentOrientation;
+ (void) setCurrentOrientation: (int)_orientation;
+ (void) leaveBreadcrumb:(NSString *)breadcrumb;
+ (void) setOptOutStatus: (BOOL) _optOutStatus;
+ (BOOL) getOptOutStatus;

// Beta Features: Email support@crittercism.com for access
+ (BOOL) logHandledException:(NSException *)exception;

@end

