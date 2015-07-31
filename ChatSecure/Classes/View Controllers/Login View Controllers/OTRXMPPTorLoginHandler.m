//
//  OTRXMPPTorLoginHandler.m
//  ChatSecure
//
//  Created by David Chiles on 5/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPTorLoginHandler.h"
#import "OTRTorManager.h"

@implementation OTRXMPPTorLoginHandler

- (void)performActionWithValidForm:(XLFormDescriptor *)form account:(OTRAccount *)account completion:(void (^)(OTRAccount * account, NSError *error))completion
{
    //check tor is running
    if ([OTRTorManager sharedInstance].torManager.status == CPAStatusOpen) {
        [super performActionWithValidForm:form account:account completion:completion];
    } else if ([OTRTorManager sharedInstance].torManager.status == CPAStatusClosed) {
        [[OTRTorManager sharedInstance].torManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(account,error);
                });
            } else {
                [super performActionWithValidForm:form account:account completion:completion];
            }
        } progress:^(NSInteger progress, NSString *summaryString) {
            
        }];
    }
}

@end
