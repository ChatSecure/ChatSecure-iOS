//
//  OTRXLFormCreator.h
//  ChatSecure
//
//  Created by David Chiles on 5/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRAccount.h"

@class XLFormDescriptor;

extern NSString *const kOTRXLFormUsernameTextFieldTag;
extern NSString *const kOTRXLFormPasswordTextFieldTag;
extern NSString *const kOTRXLFormRememberPasswordSwitchTag;
extern NSString *const kOTRXLFormLoginAutomaticallySwitchTag;
extern NSString *const kOTRXLFormHostnameTextFieldTag;
extern NSString *const kOTRXLFormPortTextFieldTag;
extern NSString *const kOTRXLFormResourceTextFieldTag;
extern NSString *const kOTRXLFormXMPPServerTag;

@interface OTRXLFormCreator : NSObject

+ (XLFormDescriptor *)formForAccount:(OTRAccount *)account;

+ (XLFormDescriptor *)formForAccountType:(OTRAccountType)accountType createAccount:(BOOL)createAccount;


@end
