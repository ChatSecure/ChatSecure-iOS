//
//  ANIPInformation.h
//  ANNetworkTools
//
//  Created by Alex Nichol on 11/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANIPInformation : NSObject {

}

+ (NSArray *)ipAddresses;
+ (UInt32)ipAddressGuess;

@end
