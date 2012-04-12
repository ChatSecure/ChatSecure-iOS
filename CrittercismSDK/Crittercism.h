//
//  Crittercism.h
//  Crittercism-iOS
//
//  Created by Robert Kwok on 8/15/10.
//  Copyright 2010-2012 Crittercism Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CrittercismJSONKit.h"
#import <QuartzCore/QuartzCore.h>
#import "CrittercismReachability.h"
//#import "<CoreLocation/CoreLocation.h>"

// Support Forum
@class CrittercismViewController;

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

    // Support Forum
    NSObject *voteDisplayer;
    CrittercismViewController *crittercismViewController;
    NSArray *feedbackArray;
}

@property(retain) id <CrittercismDelegate> delegate;
@property(assign) BOOL didCrashOnLastLoad;

// Support Forum
@property(nonatomic, retain) CrittercismViewController *crittercismViewController;
@property(nonatomic, retain) NSObject *voteDisplayer;
@property(retain) NSArray *feedbackArray;

+ (Crittercism *)sharedInstance;
+ (void) initWithAppID:(NSString *)_app_id andKey:(NSString *)_keyStr andSecret:(NSString *)_secretStr;
+ (void) initWithAppID:(NSString *)_app_id andKey:(NSString *)_keyStr andSecret:(NSString *)_secretStr andMainViewController:(UIViewController *)_mainViewController;
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

// Support Forum
+ (void)showCrittercism;
+ (void)showCrittercism:(UIViewController *)_mainViewController;
- (CrittercismViewController *) getCrittercism;
- (UIViewController *) getMainViewController;
- (void) setTintRed:(float) _red green:(float)_green blue:(float)_blue;
- (void) hideCrittercism;
- (void) setDisplayer:(NSObject *)_displayer;
- (void) updateVotes;
- (void) addVote:(NSString *)_eventName;
- (void) addVote;
- (int) getVotes;
- (void) setVotes:(int) _numVotes;
- (void) setNavTitle:(NSString *)_title;
- (NSString *) getNavTitle;
- (void) addGradient:(UIButton *) _button;

@end
