//
//  main.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyTest.h"

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	MyTest * test = [[MyTest alloc] init];
	[test beginTest];
	[[NSRunLoop currentRunLoop] run];
	[test release];

	[pool drain];
    return 0;
}

