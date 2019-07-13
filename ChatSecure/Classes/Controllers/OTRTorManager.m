//
//  OTRTorManager.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 10/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRTorManager.h"
@import Tor;

@implementation OTRTorManager

- (instancetype) init {
    if (self = [super init]) {
        // Tor.framework
        [self setupTorFramework];
    }
    return self;
}

- (void) setupTorFramework {
    NSString *dataDirectory = [[[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"com.ChatSecure.Tor"] path];
    
    TORConfiguration *configuration = [TORConfiguration new];
    configuration.cookieAuthentication = @(YES);
    configuration.dataDirectory = dataDirectory;
    NSString *SOCKSPort = @(OTRTorManager.SOCKSPort).stringValue;
    configuration.arguments = @[@"--ignore-missing-torrc",
                                @"--socksport", SOCKSPort,
                                @"--controlport", @"127.0.0.1:49060",];
    
    TORThread *thread = [[TORThread alloc] initWithConfiguration:configuration];
    [thread start];
    
    NSURL *cookieURL = [configuration.dataDirectory URLByAppendingPathComponent:@"control_auth_cookie"];
    NSData *cookie = [NSData dataWithContentsOfURL:cookieURL];
    _torController = [[TORController alloc] initWithSocketHost:@"127.0.0.1" port:49060];
    [_torController authenticateWithData:cookie completion:^(BOOL success, NSError *error) {
        if (!success)
            return;
        
        id circuitObserver = nil;
        circuitObserver = [_torController addObserverForCircuitEstablished:^(BOOL established) {
            if (!established)
                return;
            NSLog(@"Tor connected");
            [_torController removeObserver:circuitObserver];
        }];
    }];
}

#pragma - mark Singleton Methodd

+ (instancetype)sharedInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

+ (OTRTorManager*) shared {
    return [self sharedInstance];
}

+ (NSString*) SOCKSHost {
    return @"127.0.0.1";
}

+ (uint16_t) SOCKSPort {
    return 49050;
}

@end
