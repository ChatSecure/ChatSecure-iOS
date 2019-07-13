//
//  OTRConstants.h
//  Off the Record
//
//  Created by David Chiles on 6/28/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

@import UIKit;

NS_ASSUME_NONNULL_BEGIN
extern NSString *const kOTRProtocolLoginSuccess;

extern NSString *const kOTRProtocolTypeXMPP;
extern NSString *const kOTRProtocolTypeAIM;

extern NSString *const kOTRNotificationAccountNameKey;
extern NSString *const kOTRNotificationUserNameKey;
extern NSString *const kOTRNotificationProtocolKey;
extern NSString *const kOTRNotificationBuddyUniqueIdKey;
extern NSString *const kOTRNotificationAccountUniqueIdKey;
extern NSString *const kOTRNotificationAccountCollectionKey;


extern NSString *const kOTRServiceName;
extern NSString *const kOTRCertificateServiceName;

extern NSString *const kOTRSettingKeyFontSize;
extern NSString *const kOTRSettingKeyDeleteOnDisconnect;
extern NSString *const kOTRSettingKeyAllowDBPassphraseBackup;
extern NSString *const kOTRSettingKeyShowDisconnectionWarning;
extern NSString *const kOTRSettingUserAgreedToEULA;
extern NSString *const kOTRSettingAccountsKey;
extern NSString *const kOTRSettingsValueUpdatedNotification;

extern NSString *const kOTRAppVersionKey;

extern NSString *const OTRArchiverKey;

extern NSString *const OTRSuccessfulRemoteNotificationRegistration;

extern NSString *const OTRYapDatabasePassphraseAccountName;
extern NSString *const OTRYapDatabaseName;

//Notifications

/// Used to lookup account for connection errors
extern NSString *const kOTRNotificationAccountKey;
extern NSString *const kOTRNotificationThreadKey;
extern NSString *const kOTRNotificationThreadCollection;
extern NSString *const kOTRNotificationType;
extern NSString *const kOTRNotificationTypeNone;
extern NSString *const kOTRNotificationTypeSubscriptionRequest;
extern NSString *const kOTRNotificationTypeApprovedBuddy;
extern NSString *const kOTRNotificationTypeConnectionError;
extern NSString *const kOTRNotificationTypeChatMessage;
extern NSString *const OTRUserNotificationsChanged;
/** This is fired when you have a change to a device on a push account */
extern NSString *const OTRPushAccountDeviceChanged;
/** This is fired when you have a change to your tokens */
extern NSString *const OTRPushAccountTokensChanged;


extern NSString *const OTRUserNotificationsUNTextInputReply;


//NSUserDefaults
extern NSString *const kOTRDeletedFacebookKey;
extern NSString *const kOTRPushEnabledKey;
extern NSString *const kOTRIgnoreDonationDateKey;
/** Shows OMEMO Group Encryption toggle on group chat screen */
extern NSString *const kOTRShowOMEMOGroupEncryptionKey;
/** Enables or disables debug file logging */
extern NSString *const kOTREnableDebugLoggingKey;

//Chatview
extern CGFloat const kOTRSentDateFontSize;
extern CGFloat const kOTRDeliveredFontSize;
extern CGFloat const kOTRMessageFontSize;
extern CGFloat const kOTRMessageSentDateLabelHeight;
extern CGFloat const kOTRMessageDeliveredLabelHeight;

extern NSString *const kOTRErrorDomain;

extern NSUInteger const kOTRMinimumPassphraseLength;
extern NSUInteger const kOTRMaximumPassphraseLength;

NS_ASSUME_NONNULL_END
