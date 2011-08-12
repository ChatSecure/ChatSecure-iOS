//
//  OFTCheckSum.h
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Calculate oft checksum of buffer
 *
 * Prevcheck should be 0xFFFF0000 when starting a checksum of a file.  The
 * checksum is kind of a rolling checksum thing, so each time you get bytes
 * of a file you just call this puppy and it updates the checksum.  You can
 * calculate the checksum of an entire file by calling this in a while or a
 * for loop, or something.
 *
 * Thanks to Graham Booker for providing this improved checksum routine,
 * which is simpler and should be more accurate than Josh Myer's original
 * code. -- wtm
 *
 * This algorithm works every time I have tried it.  The other fails
 * sometimes.  So, AOL who thought this up?  It has got to be the weirdest
 * checksum I have ever seen.
 *
 * @param buffer Buffer of data to checksum.  Man I'd like to buff her...
 * @param bufsize Size of buffer.
 * @param prevchecksum Previous checksum.
 * @param odd Whether an odd number of bytes have been processed before this call
 */
UInt32 peer_oft_checksum_chunk(const unsigned char * buffer, int bufferlen, UInt32 prevchecksum, int odd);
