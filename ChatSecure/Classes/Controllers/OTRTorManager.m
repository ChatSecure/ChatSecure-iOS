//
//  OTRTorManager.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 10/3/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRTorManager.h"

@import CPAProxy;

@implementation OTRTorManager

- (instancetype) init {
    if (self = [super init]) {
        // Get resource paths for the torrc and geoip files from the main bundle
        NSBundle *cpaProxyFrameworkBundle = [NSBundle bundleForClass:[CPAProxyManager class]];
        NSURL *cpaProxyBundleURL = [cpaProxyFrameworkBundle URLForResource:@"CPAProxy" withExtension:@"bundle"];
        NSBundle *cpaProxyBundle = [[NSBundle alloc] initWithURL:cpaProxyBundleURL];
        NSParameterAssert(cpaProxyBundle != nil);

        NSString *torrcPath = [[NSBundle mainBundle] pathForResource:@"torrc" ofType:nil]; // use custom torrc
        NSString *geoipPath = [cpaProxyBundle pathForResource:@"geoip" ofType:nil];
        NSString *dataDirectory = [[[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"com.ChatSecure.Tor"] path];
        
        // Initialize a CPAProxyManager
        CPAConfiguration *configuration = [CPAConfiguration configurationWithTorrcPath:torrcPath geoipPath:geoipPath torDataDirectoryPath:dataDirectory];
        configuration.isolateDestinationAddress = YES;
        configuration.isolateDestinationPort = YES;
        self.torManager = [CPAProxyManager proxyWithConfiguration:configuration];
    }
    return self;
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

@end
