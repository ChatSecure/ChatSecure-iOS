//
//  AIMBArtIDWName.h
//  LibOrange
//
//  Created by Alex Nichol on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCARPacket.h"
#import "AIMBArtID.h"

@interface AIMBArtIDWName : NSObject <OSCARPacket> {
    NSString * username;
	NSArray * bartIDs;
}

@property (readonly) NSString * username;
@property (readonly) NSArray * bartIDs;

- (id)initWithNick:(NSString *)uname bartIds:(NSArray *)barts;

@end
