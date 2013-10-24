//
//  OTRCapabilitiesInMemoryCoreDataStorage.m
//  Off the Record
//
//  Created by David Chiles on 10/24/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRCapabilitiesInMemoryCoreDataStorage.h"

@implementation OTRCapabilitiesInMemoryCoreDataStorage

static XMPPCapabilitiesCoreDataStorage *sharedInstance;

+ (XMPPCapabilitiesCoreDataStorage *)sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sharedInstance = [[XMPPCapabilitiesCoreDataStorage alloc] initWithInMemoryStore];
	});
	
	return sharedInstance;
}

@end
