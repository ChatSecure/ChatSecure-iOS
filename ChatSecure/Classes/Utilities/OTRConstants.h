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

extern NSString *const kOTRProtocolLoginSuccess;
extern NSString *const kOTRProtocolLoginFail;
extern NSString *const kOTRProtocolLoginFailErrorKey;
extern NSString *const kOTRProtocolLoginFailSSLStatusKey;
extern NSString *const kOTRProtocolLoginFailHostnameKey;
extern NSString *const kOTRProtocolLoginFailSSLCertificateDataKey;
extern NSString *const kOTRNotificationErrorKey;
extern NSString *const kOTRProtocolLoginUserInitiated;

extern NSString *const kOTRGoogleTalkDomain;
extern NSString *const kOTRProtocolTypeXMPP;
extern NSString *const kOTRProtocolTypeAIM;

extern NSString *const kOTRNotificationAccountNameKey;
extern NSString *const kOTRNotificationUserNameKey;
extern NSString *const kOTRNotificationProtocolKey;
extern NSString *const kOTRNotificationBuddyUniqueIdKey;

extern NSString *const kOTRXMPPAccountSendDeliveryReceiptsKey;
extern NSString *const kOTRXMPPAccountSendTypingNotificationsKey;

extern NSString *const kOTRXMPPResource;

extern NSString *const kOTRFeedbackEmail;

extern NSString *const kOTRServiceName;
extern NSString *const kOTRCertificateServiceName;

extern NSString *const kOTRSettingKeyFontSize;
extern NSString *const kOTRSettingKeyDeleteOnDisconnect;
extern NSString *const kOTRSettingKeyOpportunisticOtr;
extern NSString *const kOTRSettingKeyShowDisconnectionWarning;
extern NSString *const kOTRSettingUserAgreedToEULA;
extern NSString *const kOTRSettingAccountsKey;
extern NSString *const kOTRSettingKeyLanguage;
extern NSString *const kOTRSettingsValueUpdatedNotification;

extern NSString *const kOTRAppVersionKey;

extern NSString *const OTRArchiverKey;

extern NSString *const GOOGLE_APP_ID;
extern NSString *const GOOGLE_APP_SCOPE;

extern NSString *const OTRFailedRemoteNotificationRegistration;
extern NSString *const OTRSuccessfulRemoteNotificationRegistration;

extern NSString *const OTRYapDatabasePassphraseAccountName;
extern NSString *const OTRYapDatabaseName;

//NSUserDefaults
extern NSString *const kOTRDeletedFacebookKey;

//Chatview
extern CGFloat const kOTRSentDateFontSize;
extern CGFloat const kOTRDeliveredFontSize;
extern CGFloat const kOTRMessageFontSize;
extern CGFloat const kOTRMessageSentDateLabelHeight;
extern CGFloat const kOTRMessageDeliveredLabelHeight;

extern NSString *const kOTRErrorDomain;

extern NSUInteger const kOTRMinimumPassphraseLength;
extern NSUInteger const kOTRMaximumPassphraseLength;
