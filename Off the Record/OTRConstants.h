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

#define kOTRProtocolLoginSuccess @"LoginSuccessNotification"
#define kOTRProtocolLoginFail @"LoginFailedNotification"
#define kOTRBuddyListUpdate @"BuddyListUpdateNotification"
#define kOTRMessageReceived @"MessageReceivedNotification"
#define kOTRMessageReceiptResonseReceived @"MessageReceiptResponseNotification"
#define kOTRStatusUpdate @"StatusUpdatedNotification" 
#define kOTRProtocolDiconnect @"DisconnectedNotification"
#define kOTRSendMessage @"SendMessageNotification"

#define kOTRFacebookDomain @"chat.facebook.com"
#define kOTRGoogleTalkDomain @"talk.google.com"
#define kOTRProtocolTypeXMPP @"xmpp"
#define kOTRProtocolTypeAIM @"prpl-oscar"

#define kOTRNotificationAccountNameKey @"kOTRNotificationAccountNameKey"
#define kOTRNotificationUserNameKey @"kOTRNotificationUserNameKey"
#define kOTRNotificationProtocolKey @"kOTRNotificationProtocolKey"

#define kOTRXMPPAccountAllowSelfSignedSSLKey @"kOTRXMPPAccountAllowSelfSignedSSLKey"
#define kOTRXMPPAccountSendDeliveryReceiptsKey @"kOTRXMPPAccountSendDeliveryReceiptsKey"
#define kOTRXMPPAccountSendTypingNotificationsKey @"kOTRXMPPAccountSendTypingNotificationsKey"
#define kOTRXMPPAccountAllowSSLHostNameMismatch @"kOTRXMPPAccountAllowSSLHostNameMismatch"
#define kOTRXMPPAccountPortNumber @"kOTRXMPPAccountPortNumber"
#define kOTRXMPPAllowPlaintextAuthenticationKey @"kOTRXMPPAllowPlaintextAuthenticationKey"
#define kOTRXMPPRequireTLSKey @"kOTRXMPPRequireTLSKey"

#define kOTRXMPPResource @"chatsecure"

#define kOTRFacebookUsernameLink @"http://www.facebook.com/help/?faq=211813265517027#What-are-usernames?"

#define kOTRFeedbackEmail @"support@chatsecure.org"

#define kOTRChatStatePausedTimeout 5
#define kOTRChatStateInactiveTimeout 120

//typedef int16_t OTRBuddyStatus;
//typedef int16_t OTRChatState;

#define MESSAGE_PROCESSED_NOTIFICATION @"MessageProcessedNotification"
#define kOTREncryptionStateNotification @"kOTREncryptionStateNotification"

#define kOTRSettingKeyFontSize @"kOTRSettingKeyFontSize"
#define kOTRSettingKeyDeleteOnDisconnect @"kOTRSettingKeyDeleteOnDisconnect"
#define kOTRSettingKeyShowDisconnectionWarning @"kOTRSettingKeyShowDisconnectionWarning"
#define kOTRSettingUserAgreedToEULA @"kOTRSettingUserAgreedToEULA"
#define kOTRSettingAccountsKey @"kOTRSettingAccountsKey"
#define kOTRSettingKeyLanguage @"userSelectedSetting"


typedef enum {
    kOTRBuddyStatusOffline = 4,
    kOTRBuddyStatusXa = 3,
    kOTRBUddyStatusDnd = 2,
    kOTRBuddyStatusAway = 1,
    kOTRBuddyStatusAvailable = 0
} OTRBuddyStatus;

typedef enum {
    kOTRChatStateUnknown =0,
    kOTRChatStateActive = 1,
    kOTRChatStateComposing = 2,
    kOTRChatStatePaused = 3,
    kOTRChatStateInactive = 4,
    kOTRChatStateGone =5
} OTRChatState;

//Chatview
#define kTabBarHeight 0
#define kSendButtonWidth 60
#define ACTIONSHEET_SAFARI_TAG 0
#define ACTIONSHEET_ENCRYPTION_OPTIONS_TAG 1

#define ALERTVIEW_NOT_VERIFIED_TAG 0
#define ALERTVIEW_VERIFIED_TAG 1

#define kChatBarHeight1                      40
#define kChatBarHeight4                      94
#define SentDateFontSize                     13
#define DeliveredFontSize                    13
#define MESSAGE_DELIVERED_LABEL_HEIGHT       (DeliveredFontSize +7)
#define MESSAGE_SENT_DATE_LABEL_HEIGHT       (SentDateFontSize+7)
#define MessageFontSize                      16
#define MESSAGE_TEXT_WIDTH_MAX               180
#define MESSAGE_MARGIN_TOP                   7
#define MESSAGE_MARGIN_BOTTOM                10
#define TEXT_VIEW_X                          7   // 40  (with CameraButton)
#define TEXT_VIEW_Y                          9
#define TEXT_VIEW_WIDTH                      249 // 216 (with CameraButton)
#define TEXT_VIEW_HEIGHT_MIN                 36
#define ContentHeightMax                     80
#define MESSAGE_COUNT_LIMIT                  50
#define MESSAGE_SENT_DATE_SHOW_TIME_INTERVAL 5*60 // 5 minutes
#define MESSAGE_SENT_DATE_LABEL_TAG          100
#define MESSAGE_BACKGROUND_IMAGE_VIEW_TAG    101
#define MESSAGE_TEXT_LABEL_TAG               102
#define MESSAGE_DELIVERED_LABEL_TAG          103
#define STATUS_MESSAGE_LABEL_TAG             104

