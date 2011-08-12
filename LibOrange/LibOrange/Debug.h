//
//  Debug.h
//  LibOrange
//
//  Created by Alex Nichol on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Debug : NSObject {
    BOOL loggingEnabled;
}

+ (void)log:(NSString *)string;
+ (void)setDebuggingEnabled:(BOOL)showDebugInfo;

@end
