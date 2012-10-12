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
#define kOTRProtocolLogout @"LogoutNotification"
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
#define kOTRXMPPAccountAllowSSLHostNameMismatch @"kOTRXMPPAccountAllowSSLHostNameMismatch"
#define kOTRXMPPAccountPortNumber @"kOTRXMPPAccountPortNumber"

#define kOTRXMPPResource @"chatsecure"

#define kOTRFacebookUsernameLink @"http://www.facebook.com/help/?faq=211813265517027#What-are-usernames?"

#define kOTRChatStatePausedTimeout 5
#define kOTRChatStateInactiveTimeout 120


