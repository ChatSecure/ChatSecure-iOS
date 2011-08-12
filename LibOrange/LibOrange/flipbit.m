/*
 *  flipbit.c
 *  OSCARAPI
 *
 *  Created by Alex Nichol on 2/23/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import "flipbit.h"

char * flipBytes (char * cs, int length) {
	char * newBytes = (char *)malloc(length);
	for (int i = 0; i < length; i++) {
		newBytes[length - (i + 1)] = cs[i];
	}
	for (int i = 0; i < length; i++) {
		cs[i] = newBytes[i];
	}
	free(newBytes);
	return cs;
}

UInt16 flipUInt16 (UInt16 cs) {
	UInt16 answer = cs;
	char * bytes = (char *)(&answer);
	flipBytes(bytes, 2);
	return answer;
}

UInt32 flipUInt32 (UInt32 cs) {
	UInt32 answer = cs;
	char * bytes = (char *)(&answer);
	flipBytes(bytes, 4);
	return answer;
}
