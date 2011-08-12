//
//  CommandTokenizer.h
//  LibOrange
//
//  Created by Alex Nichol on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CommandTokenizer : NSObject {
    NSString * remaining;
}

- (id)initWithString:(NSString *)command;
- (NSString *)nextToken;

+ (NSArray *)tokensOfCommand:(NSString *)command;

@end
