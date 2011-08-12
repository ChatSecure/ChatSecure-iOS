//
//  OFTCheckSum.c
//  LibOrange
//
//  Created by Alex Nichol on 6/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "OFTCheckSum.h"

UInt32 peer_oft_checksum_chunk(const unsigned char * buffer, int bufferlen, UInt32 prevchecksum, int odd) {
	UInt32 checksum, oldchecksum;
	int i = 0;
	UInt16 val;
	
	checksum = (prevchecksum >> 16) & 0xffff;
	if (odd)
	{
		/*
		 * This is one hell of a hack, but it should always work.
		 * Essentially, I am reindexing the array so that index 1
		 * is the first element.  Since the odd and even bytes are
		 * detected by the index number.
		 */
		i = 1;
		bufferlen++;
		buffer--;
	}
	for (; i < bufferlen; i++)
	{
		oldchecksum = checksum;
		if (i & 1)
			val = buffer[i];
		else
			val = buffer[i] << 8;
		checksum -= val;
		/*
		 * The following appears to be necessary.... It happens
		 * every once in a while and the checksum doesn't fail.
		 */
		if (checksum > oldchecksum)
			checksum--;
	}
	checksum = ((checksum & 0x0000ffff) + (checksum >> 16));
	checksum = ((checksum & 0x0000ffff) + (checksum >> 16));
	return checksum << 16;
}
