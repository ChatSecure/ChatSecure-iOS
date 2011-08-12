//
//  OFTProxyConnection.h
//  LibOrange
//
//  Created by Alex Nichol on 6/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OFTProxyCommand.h"

@interface OFTProxyConnection : NSObject {
    int fileDescriptor;
}

- (id)initWithFileDescriptor:(int)anOpenFd;
- (BOOL)writeCommand:(OFTProxyCommand *)cmd;
- (OFTProxyCommand *)readCommand;

@end
