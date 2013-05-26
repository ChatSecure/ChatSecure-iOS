//
//  OTRPushManager.m
//  Off the Record
//
//  Created by Christopher Ballinger on 5/26/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import "OTRPushManager.h"
#import "OTRConstants.h"

@implementation OTRPushManager
@synthesize account;

- (void) sendMessage:(OTRManagedMessage*)message {
    
}
- (void) connectWithPassword:(NSString *)password {
    NSLog(@"Connect with password!");
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolLoginSuccess object:nil];
}
- (void) disconnect {
    [[NSNotificationCenter defaultCenter] postNotificationName:kOTRProtocolDiconnect object:nil];

}
- (void) addBuddy:(OTRManagedBuddy *)newBuddy {
    
}
- (BOOL) isConnected {
    return YES;
}

-(void) removeBuddies:(NSArray *)buddies {
    
}
-(void) blockBuddies:(NSArray *)buddies {
    
}

@end
