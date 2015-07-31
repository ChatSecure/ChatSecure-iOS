//
//  OTRPasswordGenerator.m
//  ChatSecure
//
//  Created by David Chiles on 10/21/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRPasswordGenerator.h"

NSUInteger const OTRDefaultPasswordLength = 100;

@implementation OTRPasswordGenerator

+ (NSString *)passwordWithLength:(NSUInteger)length {
    NSMutableData* passphraseData = [NSMutableData dataWithLength:length];
    SecRandomCopyBytes(kSecRandomDefault, length, [passphraseData mutableBytes]);
    NSString *passphrase = [passphraseData base64EncodedStringWithOptions:0];
    return passphrase;
}

@end
