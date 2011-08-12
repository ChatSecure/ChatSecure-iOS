//
//  Debug.m
//  LibOrange
//
//  Created by Alex Nichol on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Debug.h"

@interface Debug (Private)

+ (Debug *)sharedDebug;
- (BOOL)debug;
- (void)setDebug:(BOOL)doIt;

@end

@implementation Debug

+ (Debug *)sharedDebug {
	static Debug * d = nil;
	if (!d) {
		d = [[Debug alloc] init];
	}
	return d;
}

- (BOOL)debug {
	return loggingEnabled;
}
- (void)setDebug:(BOOL)doIt {
	loggingEnabled = doIt;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (void)log:(NSString *)string {
	if ([[self sharedDebug] debug]) {
		NSLog(@"%@", string);
	}
}
+ (void)setDebuggingEnabled:(BOOL)showDebugInfo {
	[[self sharedDebug] setDebug:showDebugInfo];
}

- (void)dealloc {
    [super dealloc];
}

@end
