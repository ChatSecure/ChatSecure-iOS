//
//  OSCARPacket.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol OSCARPacket <NSCopying, NSCoding>

/**
 * Creates a new packet by decoding data that was presumably received over
 * a connection or read from a file.
 * @param data The entire packet as encoded data.
 */
- (id)initWithData:(NSData *)data;

/**
 * Reads up to *length bytes for decoding.
 * @param ptr The pointer from which the function will read data.
 * @param length A pointer to the data's total length.  This will be changed
 * to the amount of bytes that were used by the decoder.
 * @return nil if the object could not be decoded.  A freshly allocated object otherwise.
 */
- (id)initWithPointer:(const char *)ptr length:(int *)length;

/**
 * Encodes the packets complete data, including all of its potential headers.
 * The result of this function should be able to be passed back into
 * initWithData:.
 * @return The encoded data, or nil on error.
 */
- (NSData *)encodePacket;

@end
