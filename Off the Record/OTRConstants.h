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

static NSString *const kOTRProtocolLoginSuccess                   = @"LoginSuccessNotification";
static NSString *const kOTRProtocolLoginFail                      = @"LoginFailedNotification";
static NSString *const kOTRProtocolLoginFailErrorKey              = @"ProtocolLoginFailErrorKey";
static NSString *const kOTRProtocolLoginFailSSLStatusKey          = @"kOTRProtocolLoginFailSSLStatusKey";
static NSString *const kOTRProtocolLoginFailHostnameKey           = @"kOTRProtocolLoginFailHostnameKey";
static NSString *const kOTRProtocolLoginFailSSLCertificateDataKey = @"kOTRProtocolLoginFailSSLCertificateData";
static NSString *const kOTRMessageReceived                        = @"MessageReceivedNotification";
static NSString *const kOTRMessageReceiptResonseReceived          = @"MessageReceiptResponseNotification";
static NSString *const kOTRStatusUpdate                           = @"StatusUpdatedNotification";
static NSString *const kOTRProtocolDiconnect                      = @"DisconnectedNotification";
static NSString *const kOTRSendMessage                            = @"SendMessageNotification";

static NSString *const kOTRFacebookDomain   = @"chat.facebook.com";
static NSString *const kOTRGoogleTalkDomain = @"talk.google.com";
static NSString *const kOTRProtocolTypeXMPP = @"xmpp";
static NSString *const kOTRProtocolTypeAIM  = @"prpl-oscar";

static NSString *const kOTRNotificationAccountNameKey = @"kOTRNotificationAccountNameKey";
static NSString *const kOTRNotificationUserNameKey    = @"kOTRNotificationUserNameKey";
static NSString *const kOTRNotificationProtocolKey    = @"kOTRNotificationProtocolKey";

static NSString *const kOTRXMPPAccountAllowSelfSignedSSLKey      = @"kOTRXMPPAccountAllowSelfSignedSSLKey";
static NSString *const kOTRXMPPAccountSendDeliveryReceiptsKey    = @"kOTRXMPPAccountSendDeliveryReceiptsKey";
static NSString *const kOTRXMPPAccountSendTypingNotificationsKey = @"kOTRXMPPAccountSendTypingNotificationsKey";
static NSString *const kOTRXMPPAccountAllowSSLHostNameMismatch   = @"kOTRXMPPAccountAllowSSLHostNameMismatch";
static NSString *const kOTRXMPPAccountPortNumber                 = @"kOTRXMPPAccountPortNumber";
static NSString *const kOTRXMPPAllowPlaintextAuthenticationKey   = @"kOTRXMPPAllowPlaintextAuthenticationKey";
static NSString *const kOTRXMPPRequireTLSKey                     = @"kOTRXMPPRequireTLSKey";

static NSString *const kOTRXMPPResource = @"chatsecure";

static NSString *const kOTRFacebookUsernameLink = @"http://www.facebook.com/help/?faq=211813265517027#What-are-usernames?";

static NSString *const kOTRFeedbackEmail = @"support@chatsecure.org";

static NSString *const kOTRServiceName            = @"org.chatsecure.ChatSecure";
static NSString *const kOTRCertificateServiceName = @"org.chatsecure.ChatSecure.Certificate";

static NSString *const MESSAGE_PROCESSED_NOTIFICATION  = @"MessageProcessedNotification";
static NSString *const kOTREncryptionStateNotification = @"kOTREncryptionStateNotification";

static NSString *const kOTRSettingKeyFontSize                 = @"kOTRSettingKeyFontSize";
static NSString *const kOTRSettingKeyDeleteOnDisconnect       = @"kOTRSettingKeyDeleteOnDisconnect";
static NSString *const kOTRSettingKeyOpportunisticOtr         = @"kOTRSettingKeyOpportunisticOtr";
static NSString *const kOTRSettingKeyShowDisconnectionWarning = @"kOTRSettingKeyShowDisconnectionWarning";
static NSString *const kOTRSettingUserAgreedToEULA            = @"kOTRSettingUserAgreedToEULA";
static NSString *const kOTRSettingAccountsKey                 = @"kOTRSettingAccountsKey";
static NSString *const kOTRSettingKeyLanguage                 = @"userSelectedSetting";

static NSString *const kOTRAppVersionKey     = @"kOTRAppVersionKey";
static NSString *const OTRActivityTypeQRCode = @"OTRActivityTypeQRCode";

static NSString *const OTRArchiverKey = @"OTRArchiverKey";

static NSString *const FACEBOOK_APP_ID  = @"447241325394334";
static NSString *const GOOGLE_APP_ID    = @"719137339288.apps.googleusercontent.com";
static NSString *const GOOGLE_APP_SCOPE = @"https://www.googleapis.com/auth/googletalk";

//Chatview
static CGFloat const sentDateFontSize            = 13;
static CGFloat const deliveredFontSize           = 13;
static CGFloat const messageFontSize             = 16;
static CGFloat const messageSentDateLabelHeight  = sentDateFontSize + 7;
static CGFloat const messageDeliveredLabelHeight = deliveredFontSize + 7;


typedef enum {
    kOTRChatStateUnknown   = 0,
    kOTRChatStateActive    = 1,
    kOTRChatStateComposing = 2,
    kOTRChatStatePaused    = 3,
    kOTRChatStateInactive  = 4,
    kOTRChatStateGone      = 5
} OTRChatState;

typedef NS_ENUM(NSUInteger, OTRAccountType) {
    OTRAccountTypeNone        = 0,
    OTRAccountTypeFacebook    = 1,
    OTRAccountTypeGoogleTalk  = 2,
    OTRAccountTypeJabber      = 3,
    OTRAccountTypeAIM         = 4
};

typedef NS_ENUM(NSUInteger, OTRProtocolType) {
    OTRProtocolTypeNone        = 0,
    OTRProtocolTypeXMPP        = 1,
    OTRProtocolTypeOscar       = 2
};

typedef NS_ENUM(NSUInteger, OTRBuddyStatus) {
    OTRBuddyStatusOffline   = 4,
    OTRBuddyStatusXa        = 3,
    OTRBuddyStatusDnd       = 2,
    OTRBuddyStatusAway      = 1,
    OTRBuddyStatusAvailable = 0
};




