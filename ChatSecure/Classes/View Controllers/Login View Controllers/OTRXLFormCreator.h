//
//  OTRXLFormCreator.h
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

@import Foundation;
@import XLForm;
#import "OTRAccount.h"

NS_ASSUME_NONNULL_BEGIN
extern NSString *const kOTRXLFormCustomizeUsernameSwitchTag;
extern NSString *const kOTRXLFormNicknameTextFieldTag;
extern NSString *const kOTRXLFormUsernameTextFieldTag;
extern NSString *const kOTRXLFormPasswordTextFieldTag;
extern NSString *const kOTRXLFormRememberPasswordSwitchTag;
extern NSString *const kOTRXLFormLoginAutomaticallySwitchTag;
extern NSString *const kOTRXLFormHostnameTextFieldTag;
extern NSString *const kOTRXLFormPortTextFieldTag;
extern NSString *const kOTRXLFormResourceTextFieldTag;
extern NSString *const kOTRXLFormXMPPServerTag;
extern NSString *const kOTRXLFormUseTorTag;
extern NSString *const kOTRXLFormAutomaticURLFetchTag;


@interface XLFormDescriptor (OTRAccount)

/** This is for logging in with accounts that exist locally and remotely */
+ (instancetype) existingAccountFormWithAccount:(OTRAccount *)account;
/** This is for creating a local account for a pre-existing remote account */
+ (instancetype) existingAccountFormWithAccountType:(OTRAccountType)accountType;
/** This is for registering new accounts on a server */
+ (instancetype) registerNewAccountFormWithAccountType:(OTRAccountType)accountType;

@end

NS_ASSUME_NONNULL_END
