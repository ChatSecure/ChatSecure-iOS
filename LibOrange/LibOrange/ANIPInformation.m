//
//  ANIPInformation.m
//  ANNetworkTools
//
//  Created by Alex Nichol on 11/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ANIPInformation.h"

// important includes
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

@implementation ANIPInformation

+ (NSArray *)ipAddresses {
	struct ifaddrs * ifAddrStruct = NULL;
	struct ifaddrs * ifAddrStructOrig = NULL;
	void * tmpAddrPtr = NULL;
	if (getifaddrs(&ifAddrStructOrig) < 0) {
		return nil;
	}
	ifAddrStruct = ifAddrStructOrig;
	char addressBuffer[80];
	NSMutableArray * retV = [[NSMutableArray alloc] init];
	while (ifAddrStruct != NULL) {
		if (ifAddrStruct->ifa_addr->sa_family == AF_INET && strcmp(ifAddrStruct->ifa_name, "lo0") != 0 && strcmp(ifAddrStruct->ifa_name, "lo") != 0) { 
			tmpAddrPtr = &((struct sockaddr_in *)ifAddrStruct->ifa_addr)->sin_addr;
			const char * addr = (const char *)inet_ntop(AF_INET, tmpAddrPtr, addressBuffer, sizeof(struct ifaddrs));
			[retV addObject:[NSString stringWithFormat:@"%s", addr]];
		}
		ifAddrStruct = ifAddrStruct->ifa_next;
	}
	freeifaddrs(ifAddrStructOrig);
	return [retV autorelease];
}
+ (UInt32)ipAddressGuess {
	NSArray * addrs = [ANIPInformation ipAddresses];
	for (NSString * address in addrs) {
		if (![address isEqualToString:@"127.0.0.1"]) {
			// good string
			NSArray * parts = [address componentsSeparatedByString:@"."];
			if ([parts count] == 4) {
				// here we will copy the four-byte IP address into a UInt32.
				UInt32 addrRaw = 0;
				unsigned char * writable = (unsigned char *)&addrRaw;
				int index = 0;
				for (NSString * str in parts) {
					writable[index++] = (UInt8)[str intValue];
				}
				return addrRaw;
			}
		}
	}
	UInt32 localAddr = 0;
	unsigned char * writable = (unsigned char *)&localAddr;
	writable[0] = 127;
	writable[3] = 1;
	return localAddr;
}

@end
