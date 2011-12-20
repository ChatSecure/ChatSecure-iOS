//
//  ANCGIHTTPParameterReader.h
//  CGITesting
//
//  Created by Alex Nichol on 11/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ANStringEscaper.h"

@interface ANCGIHTTPParameterReader : NSObject {
	
}

+ (NSDictionary *)getAllHTTPParameters;

@end


@interface NSString (httpparameters)
- (NSDictionary *)parseHTTPParaemters;
@end

@interface NSDictionary (httpparameters)
- (NSString *)encodeHTTPParameters;
@end

@interface NSMutableDictionary (mhttpparameters)
- (NSMutableString *)encodeHTTPParameters;
@end
