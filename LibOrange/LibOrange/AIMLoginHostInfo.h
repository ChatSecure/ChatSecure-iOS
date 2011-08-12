//
//  AIMLoginHostInfo.h
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AIMLoginHostInfo : NSObject {
    NSString * hostName;
	UInt16 port;
	NSData * cookie;
}

@property (nonatomic, retain) NSString * hostName;
@property (readwrite) UInt16 port;
@property (nonatomic, retain) NSData * cookie;

- (id)initWithHost:(NSString *)theHost port:(UInt16)thePort cookie:(NSData *)theCookie;

@end
