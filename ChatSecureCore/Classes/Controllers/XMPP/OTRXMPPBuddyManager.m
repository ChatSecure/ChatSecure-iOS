//
//  OTRXMPPBuddyManager.m
//  ChatSecure
//
//  Created by David Chiles on 1/6/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPBuddyManager.h"
#import "ChatSecureCoreCompat-Swift.h"
@import XMPPFramework;
#import "OTRXMPPBuddy.h"
@import YapDatabase;

@interface OTRXMPPBuddyManager () <OTRYapViewHandlerDelegateProtocol>

@property (nonatomic, strong) OTRYapViewHandler *viewHandler;

@end

@implementation OTRXMPPBuddyManager

- (void)setDatabaseConnection:(YapDatabaseConnection *)databaseConnection
{
    _databaseConnection = databaseConnection;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    NSString *accountKey = aXmppStream.tag;
    self.viewHandler = [[OTRYapViewHandler alloc] initWithDatabaseConnection:self.databaseConnection databaseChangeNotificationName:[DatabaseNotificationName LongLivedTransactionChanges]];
    self.viewHandler.delegate = self;
    NSArray *groups = @[accountKey];
    NSString *viewName = [YapDatabaseConstants extensionName:DatabaseExtensionNameBuddyDeleteActionViewName];
    [self.viewHandler setup:viewName groups:groups];
    
    return YES;
}

- (void)deactivate {
    self.viewHandler = nil;
}

- (void)handleDatabaseViewChanges:(OTRYapViewHandler *)viewHandler {
    __block NSMutableArray *buddiesToDelete = [[NSMutableArray alloc] init];
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        YapDatabaseViewTransaction *databaseViewTransaction = [transaction ext:viewHandler.mappings.view];
        NSUInteger sectionCount = [viewHandler.mappings numberOfSections];
        for(NSUInteger section = 0; section < sectionCount; section++) {
            NSUInteger rows = [viewHandler.mappings numberOfItemsInSection:section];
            for (NSUInteger row = 0; row < rows; row++) {
                
                OTRXMPPBuddy *buddy = [databaseViewTransaction objectAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] withMappings:viewHandler.mappings];
                if (buddy) {
                    [buddiesToDelete addObject:buddy];
                }
            }
        }
        
    } completionQueue:self.moduleQueue completionBlock:^{
        if([buddiesToDelete count] > 0) {
            [self.protocol removeBuddies:buddiesToDelete];
        }
    }];
}

#pragma MARK OTRYapViewHandlerDelegateProtocol Methods

- (void)didSetupMappings:(OTRYapViewHandler *)handler
{
    [self handleDatabaseViewChanges:handler];
}

- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges {
    [self handleDatabaseViewChanges:handler];
}
@end
