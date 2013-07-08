//
//  OTRPushManager.m
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRPushManager.h"
#import "OTRConstants.h"
#import "OTRPushAPIClient.h"

@interface OTRPushManager()
@end

@implementation OTRPushManager
@synthesize account, isConnected;

- (void) sendMessage:(OTRManagedMessage*)message {
    
}
- (void) connectWithPassword:(NSString *)password {
    
    [[OTRPushAPIClient sharedClient] connectAccount:self.account password:password successBlock:^(OTRPushAccount *loggedInAccount) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolLoginSuccess object:nil];
        self.isConnected = YES;
    } failureBlock:^(NSError *error) {
        NSLog(@"Error connecting: %@", error.userInfo);
        [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolLoginFail object:nil];
        self.isConnected = NO;
    }];
}
- (void) disconnect {
    self.isConnected = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolDiconnect object:nil];

}
- (void) addBuddy:(OTRManagedBuddy *)newBuddy {
    NSLog(@"buddy add: %@", newBuddy);
}

-(void) removeBuddies:(NSArray *)buddies {
    
}
-(void) blockBuddies:(NSArray *)buddies {
    
}

@end
