//
//  OTRAccountMigrator.h
//  ChatSecure
//
//  Created by Chris Ballinger on 5/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
@class OTRXMPPAccount;

typedef NS_ENUM(NSUInteger, MigratorError) {
    MigratorErrorUnknown = 0,
    MigratorErrorInProgress
};

NS_ASSUME_NONNULL_BEGIN
@interface OTRAccountMigrator : NSObject

@property (nonatomic, strong, readonly) OTRXMPPAccount *oldAccount;
@property (nonatomic, strong, readonly) OTRXMPPAccount *migratedAccount;
@property (nonatomic, readonly) BOOL shouldSpamFriends;

- (instancetype) initWithOldAccount:(OTRXMPPAccount*)oldAccount
                    migratedAccount:(OTRXMPPAccount*)migratedAccount
                  shouldSpamFriends:(BOOL)shouldSpamFriends NS_DESIGNATED_INITIALIZER;

- (instancetype) init NS_UNAVAILABLE;

- (void) migrateWithCompletion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end
NS_ASSUME_NONNULL_END
