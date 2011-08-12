//
//  FileDescriptors.h
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "flipbit.h"


BOOL fdRead (int fd, char * buffer, int len);

/**
 * Reads and flips 2 bytes from a socket and throws them in a UInt16.
 * Returns NO if the read failed.
 */
BOOL fdReadUInt16 (int fd, UInt16 * integ);
/**
 * Reads and flips 4 bytes from a socket and throws them in a UInt32.
 * Returns NO if the read failed.
 */
BOOL fdReadUInt32 (int fd, UInt32 * integ);
