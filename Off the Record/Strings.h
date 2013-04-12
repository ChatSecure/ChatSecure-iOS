//
//  Strings.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/7/12.
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
#import "OTRLanguageManager.h"

#define EN_BUDDY_LIST_STRING @"Buddy List"
#define EN_CONVERSATIONS_STRING @"Conversations"
#define EN_ACCOUNTS_STRING @"Accounts"
#define EN_ABOUT_STRING @"About"
#define EN_CHAT_STRING @"Chat"
#define EN_CANCEL_STRING @"Cancel"
#define EN_INITIATE_ENCRYPTED_CHAT_STRING @"Initiate Encrypted Chat"
#define EN_CANCEL_ENCRYPTED_CHAT_STRING @"Cancel Encrypted Chat"
#define EN_VERIFY_STRING @"Verify"
#define EN_VERIFIED_STRING @"Verified"
#define EN_NOT_VERIFIED_STRING @"Not Verified"
#define EN_VERIFY_LATER_STRING @"Verify Later"
#define EN_CLEAR_CHAT_HISTORY_STRING @"Clear Chat History"
#define EN_SEND_STRING @"Send"
#define EN_OK_STRING @"OK"

#define EN_DONATE_STRING @"Donate"
#define EN_DONATE_MESSAGE_STRING @"Your donation will help fund the continued development of ChatSecure."

//Used in OTRChatViewController
#define EN_RECENT_STRING @"Recent"
#define EN_YOUR_FINGERPRINT_STRING @"Fingerprint for you"
#define EN_THEIR_FINGERPRINT_STRING @"Purported fingerprint for"
#define EN_SECURE_CONVERSATION_STRING @"You must be in a secure conversation first."
#define EN_VERIFY_FINGERPRINT_STRING @"Verify Fingerprint"
#define EN_CHAT_INSTRUCTIONS_LABEL_STRING @"Log in on the Settings page (found on top right corner of buddy list) and then select a buddy from the Buddy List to start chatting."
#define EN_OPEN_IN_SAFARI_STRING @"Open in Safari"
#define EN_DISCONNECTED_TITLE_STRING @"Disconnected"
#define EN_DISCONNECTED_MESSAGE_STRING @"You (%@) have disconnected."
#define EN_DISCONNECTION_WARNING_STRING @"When you leave this conversation it will be deleted forever."
#define EN_CONVERSATION_NOT_SECURE_WARNING_STRING @"Warning: This chat is not encrypted"
#define EN_CONVERSATION_NO_LONGER_SECURE_STRING @"The conversation with %@ is no longer secure."
#define EN_CONVERSATION_SECURE_WARNING_STRING @"This chat is secured"
#define EN_CONVERSATION_SECURE_AND_VERIFIED_WARNING_STRING @"This chat is secured and verified"
#define EN_CHAT_STATE_ACTIVE_STRING @"Active"
#define EN_CHAT_STATE_COMPOSING_STRING @"Typing"
#define EN_CHAT_STATE_PAUSED_STRING @"Entered Text"
#define EN_CHAT_STATE_INACTVIE_STRING @"Inactive"
#define EN_CHAT_STATE_GONE_STRING @"Gone"

// OTRBuddyListViewController
#define EN_IGNORE_STRING @"Ignore"
#define EN_REPLY_STRING @"Reply"
#define EN_OFFLINE_STRING @"Offline"
#define EN_AWAY_STRING @"Away"
#define EN_AVAILABLE_STRING @"Available"
#define EN_OFFLINE_MESSAGE_STRING @"is now offline"
#define EN_AWAY_MESSAGE_STRING @"is now away"
#define EN_AVAILABLE_MESSAGE_STRING @"is now available"
#define EN_SECURITY_WARNING_STRING @"Security Warning"
#define EN_AGREE_STRING @"Agree"
#define EN_DISAGREE_STRING @"Disagree"
#define EN_ERROR_STRING @"Error!"
#define EN_OSCAR_FAIL_STRING @"Failed to start authenticating. Please try again."
#define EN_XMPP_FAIL_STRING @"Failed to connect to XMPP server. Please check your login credentials and internet connection and try again."
#define EN_XMPP_PORT_FAIL_STRING @"Domain needs to be set manually when specifying a custom port"
#define EN_LOGGING_IN_STRING @"Logging in..."
#define EN_USER_PASS_BLANK_STRING @"You must enter a username and a password to login."
#define EN_BASIC_STRING @"Basic"
#define EN_ADVANCED_STRING @"Advanced"
#define EN_SSL_MISMATCH_STRING @"SSL Hostname Mismatch"
#define EN_SELF_SIGNED_SSL_STRING @"Self Signed SSL"
#define EN_ALLOW_PLAIN_TEXT_AUTHENTICATION_STRING @"Allow Plaintext Authentication"
#define EN_REQUIRE_TLS_STRING @"Require TLS"
#define EN_PORT_STRING @"Port"
#define EN_GOOGLE_TALK_EXAMPLE_STRING @"user@gmail.com"
#define EN_REQUIRED_STRING @"Required"
#define EN_SEND_DELIVERY_RECEIPT_STRING @"Send Delivery Receipts"
#define EN_SEND_TYPING_NOTIFICATION_STRING @"Send Typing Notificaction"
#define EN_LOGOUT_STRING @"Log Out"
#define EN_LOGIN_STRING @"Log In"
#define EN_LOGOUT_FROM_AIM_STRING @"Logout from OSCAR?"
#define EN_LOGOUT_FROM_XMPP_STRING @"Logout from XMPP?"
#define EN_DELETE_ACCOUNT_TITLE_STRING @"Delete Account?"
#define EN_DELETE_ACCOUNT_MESSAGE_STRING @"Permanently delete"
#define EN_NO_ACCOUNT_SAVED_STRING @"No Saved Accounts"
#define EN_ATTRIBUTION_STRING @"ChatSecure is brought to you by many open source projects"
#define EN_SOURCE_STRING @"Check out the source here on Github"
#define EN_CONTRIBUTE_TRANSLATION_STRING @"Contribute a translation"
#define EN_PROJECT_HOMEPAGE_STRING @"Project Homepage"
#define EN_VERSION_STRING @"Version"
#define EN_USERNAME_STRING @"Username"
#define EN_PASSWORD_STRING @"Password"
#define EN_DOMAIN_STRING @"Domain"
#define EN_LOGIN_TO_STRING @"Login to"
#define EN_REMEMBER_USERNAME_STRING @"Remember username"
#define EN_REMEMBER_PASSWORD_STRING @"Remember password"
#define EN_OPTIONAL_STRING @"Optional"
#define EN_FACEBOOK_HELP_STRING @"Your Facebook username is not the email address that you use to login to Facebook"
#define EN_CRITTERCISM_TITLE_STRING @"Send Crash Reports"
#define EN_CRITTERCISM_DESCRIPTION_STRING @"Automatically send anonymous crash logs (opt-in)"
#define EN_OTHER_STRING @"Other"
#define EN_ALLOW_SELF_SIGNED_CERTIFICATES_STRING @"Self-Signed SSL"
#define EN_ALLOW_SSL_HOSTNAME_MISMATCH_STRING @"Hostname Mismatch"
#define EN_SECURITY_WARNING_DESCRIPTION_STRING @"Warning: Use with caution! This may reduce your security."
#define EN_DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING @"Auto-delete"
#define EN_DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING @"Delete chats on disconnect"
#define EN_FONT_SIZE_STRING @"Font Size"
#define EN_FONT_SIZE_DESCRIPTION_STRING @"Size for font in chat view"
#define EN_DISCONNECTION_WARNING_TITLE_STRING @"Signout Warning"
#define EN_DISCONNECTION_WARNING_DESC_STRING @"1 Minute Alert Before Disconnection"
#define EN_DEFAULT_LANGUAGE_STRING @"Default"
#define EN_SETTINGS_STRING @"Settings"
#define EN_SHARE_STRING @"Share"
#define EN_NOT_AVAILABLE_STRING @"Not Available"
#define EN_SHARE_MESSAGE_STRING @"Chat with me securely"
#define EN_CONNECTED_STRING @"Connected"
#define EN_SEND_FEEDBACK_STRING @"Send Feedback"
#define EN_LANGUAGE_STRING @"Language"
#define EN_LANGUAGE_ALERT_TITLE_STRING @"Language Change"
#define EN_LANGUAGE_ALERT_MESSAGE_STRING @"In order to change langugages return to the home screen and remove ChatSecure from the recently used apps"
#define EN_SAVE_STRING @"Save"
#define EN_NEW_STRING @"New"
#define EN_OLD_STRING @"Old"
#define EN_DONE_STRING @"Done"
#define EN_QR_CODE_INSTRUCTIONS_STRING @"This QR Code contains a link to http://omniqrcode.com/q/chatsecure and will redirect to the App Store."
#define EN_EXPIRATION_STRING @"Background session will expire in one minute."
#define EN_READ_STRING @"Read"
#define EN_NEW_ACCOUNT_STRING @"New Account"
#define EN_AIM_STRING @"OSCAR Instant Messenger"
#define EN_GOOGLE_TALK_STRING @"Google Talk"
#define EN_FACEBOOK_STRING @"Facebook"
#define EN_JABBER_STRING @"Jabber (XMPP)"
#define EN_MESSAGE_PLACEHOLDER_STRING @"Message"
#define EN_DELIVERED_STRING @"Deliverd"
#define EN_EXTENDED_AWAY_STRING @"Extended Away"
#define EN_DO_NOT_DISTURB_STRING @"Do Not Disturb"
#define EN_PENDING_APPROVAL_STRING @"Pending Approval"
#define EN_DEFAULT_BUDDY_GROUP_STRING @"Buddies"
#define EN_EMAIL_STRING @"Email"
#define EN_NAME_STRING @"Name"
#define EN_ACCOUNT_STRING @"Account"
#define EN_GROUP_STRING @"Group"
#define EN_GROUPS_STRING @"Groups"
#define EN_REMOVE_STRING @"Remove"
#define EN_BLOCK_STRING @"Block"
#define EN_BLOCK_AND_REMOVE_STRING @"Block & Remove"
#define EN_ADD_BUDDY_STRING @"Add Buddy"
#define EN_BUDDY_INFO_STRING @"Buddy Info"



#define BUDDY_LIST_STRING [OTRLanguageManager translatedString: EN_BUDDY_LIST_STRING]
#define CONVERSATIONS_STRING [OTRLanguageManager translatedString: EN_CONVERSATIONS_STRING]
#define ACCOUNTS_STRING [OTRLanguageManager translatedString: EN_ACCOUNTS_STRING]
#define ABOUT_STRING [OTRLanguageManager translatedString: EN_ABOUT_STRING]
#define CHAT_STRING [OTRLanguageManager translatedString: EN_CHAT_STRING]
#define CANCEL_STRING [OTRLanguageManager translatedString: EN_CANCEL_STRING]
#define INITIATE_ENCRYPTED_CHAT_STRING [OTRLanguageManager translatedString: EN_INITIATE_ENCRYPTED_CHAT_STRING]
#define CANCEL_ENCRYPTED_CHAT_STRING [OTRLanguageManager translatedString: EN_CANCEL_ENCRYPTED_CHAT_STRING]
#define VERIFY_STRING [OTRLanguageManager translatedString: EN_VERIFY_STRING]
#define VERIFIED_STRING [OTRLanguageManager translatedString: EN_VERIFIED_STRING]
#define NOT_VERIFIED_STRING [OTRLanguageManager translatedString: EN_NOT_VERIFIED_STRING]
#define VERIFY_LATER_STRING [OTRLanguageManager translatedString: EN_VERIFY_LATER_STRING]
#define CLEAR_CHAT_HISTORY_STRING [OTRLanguageManager translatedString: EN_CLEAR_CHAT_HISTORY_STRING]
#define SEND_STRING [OTRLanguageManager translatedString: EN_SEND_STRING]
#define OK_STRING [OTRLanguageManager translatedString: EN_OK_STRING]
#define RECENT_STRING [OTRLanguageManager translatedString: EN_RECENT_STRING]
#define YOUR_FINGERPRINT_STRING [OTRLanguageManager translatedString: EN_YOUR_FINGERPRINT_STRING]
#define THEIR_FINGERPRINT_STRING [OTRLanguageManager translatedString: EN_THEIR_FINGERPRINT_STRING]
#define SECURE_CONVERSATION_STRING [OTRLanguageManager translatedString: EN_SECURE_CONVERSATION_STRING]
#define VERIFY_FINGERPRINT_STRING [OTRLanguageManager translatedString: EN_VERIFY_FINGERPRINT_STRING]
#define CHAT_INSTRUCTIONS_LABEL_STRING [OTRLanguageManager translatedString: EN_CHAT_INSTRUCTIONS_LABEL_STRING]
#define OPEN_IN_SAFARI_STRING [OTRLanguageManager translatedString: EN_OPEN_IN_SAFARI_STRING]
#define DISCONNECTED_TITLE_STRING [OTRLanguageManager translatedString: EN_DISCONNECTED_TITLE_STRING]
#define DISCONNECTED_MESSAGE_STRING [OTRLanguageManager translatedString: EN_DISCONNECTED_MESSAGE_STRING]
#define DISCONNECTION_WARNING_STRING [OTRLanguageManager translatedString: EN_DISCONNECTION_WARNING_STRING]
#define CONVERSATION_NOT_SECURE_WARNING_STRING [OTRLanguageManager translatedString: EN_CONVERSATION_NOT_SECURE_WARNING_STRING]
#define CONVERSATION_NO_LONGER_SECURE_STRING [OTRLanguageManager translatedString: EN_CONVERSATION_NO_LONGER_SECURE_STRING]
#define CONVERSATION_SECURE_WARNING_STRING [OTRLanguageManager translatedString: EN_CONVERSATION_SECURE_WARNING_STRING]
#define CONVERSATION_SECURE_AND_VERIFIED_WARNING_STRING [OTRLanguageManager translatedString: EN_CONVERSATION_SECURE_AND_VERIFIED_WARNING_STRING]
#define CHAT_STATE_ACTIVE_STRING [OTRLanguageManager translatedString: EN_CHAT_STATE_ACTIVE_STRING]
#define CHAT_STATE_COMPOSING_STRING [OTRLanguageManager translatedString: EN_CHAT_STATE_COMPOSING_STRING]
#define CHAT_STATE_PAUSED_STRING [OTRLanguageManager translatedString: EN_CHAT_STATE_PAUSED_STRING]
#define CHAT_STATE_INACTVIE_STRING [OTRLanguageManager translatedString: EN_CHAT_STATE_INACTVIE_STRING]
#define CHAT_STATE_GONE_STRING [OTRLanguageManager translatedString: EN_CHAT_STATE_GONE_STRING]
#define IGNORE_STRING [OTRLanguageManager translatedString: EN_IGNORE_STRING]
#define REPLY_STRING [OTRLanguageManager translatedString: EN_REPLY_STRING]
#define OFFLINE_STRING [OTRLanguageManager translatedString: EN_OFFLINE_STRING]
#define AWAY_STRING [OTRLanguageManager translatedString: EN_AWAY_STRING]
#define AVAILABLE_STRING [OTRLanguageManager translatedString: EN_AVAILABLE_STRING]
#define OFFLINE_MESSAGE_STRING [OTRLanguageManager translatedString: EN_OFFLINE_MESSAGE_STRING]
#define AWAY_MESSAGE_STRING [OTRLanguageManager translatedString: EN_AWAY_MESSAGE_STRING]
#define AVAILABLE_MESSAGE_STRING [OTRLanguageManager translatedString: EN_AVAILABLE_MESSAGE_STRING]
#define SECURITY_WARNING_STRING [OTRLanguageManager translatedString: EN_SECURITY_WARNING_STRING]
#define AGREE_STRING [OTRLanguageManager translatedString: EN_AGREE_STRING]
#define DISAGREE_STRING [OTRLanguageManager translatedString: EN_DISAGREE_STRING]
#define ERROR_STRING [OTRLanguageManager translatedString: EN_ERROR_STRING]
#define OSCAR_FAIL_STRING [OTRLanguageManager translatedString: EN_OSCAR_FAIL_STRING]
#define XMPP_FAIL_STRING [OTRLanguageManager translatedString: EN_XMPP_FAIL_STRING]
#define XMPP_PORT_FAIL_STRING [OTRLanguageManager translatedString: EN_XMPP_PORT_FAIL_STRING]
#define LOGGING_IN_STRING [OTRLanguageManager translatedString: EN_LOGGING_IN_STRING]
#define USER_PASS_BLANK_STRING [OTRLanguageManager translatedString: EN_USER_PASS_BLANK_STRING]
#define BASIC_STRING [OTRLanguageManager translatedString: EN_BASIC_STRING]
#define ADVANCED_STRING [OTRLanguageManager translatedString: EN_ADVANCED_STRING]
#define SSL_MISMATCH_STRING [OTRLanguageManager translatedString: EN_SSL_MISMATCH_STRING]
#define SELF_SIGNED_SSL_STRING [OTRLanguageManager translatedString: EN_SELF_SIGNED_SSL_STRING]
#define ALLOW_PLAIN_TEXT_AUTHENTICATION_STRING [OTRLanguageManager translatedString: EN_ALLOW_PLAIN_TEXT_AUTHENTICATION_STRING]
#define REQUIRE_TLS_STRING [OTRLanguageManager translatedString: EN_REQUIRE_TLS_STRING]
#define PORT_STRING [OTRLanguageManager translatedString: EN_PORT_STRING]
#define GOOGLE_TALK_EXAMPLE_STRING [OTRLanguageManager translatedString: EN_GOOGLE_TALK_EXAMPLE_STRING]
#define REQUIRED_STRING [OTRLanguageManager translatedString: EN_REQUIRED_STRING]
#define SEND_DELIVERY_RECEIPT_STRING [OTRLanguageManager translatedString: EN_SEND_DELIVERY_RECEIPT_STRING]
#define SEND_TYPING_NOTIFICATION_STRING [OTRLanguageManager translatedString: EN_SEND_TYPING_NOTIFICATION_STRING]
#define LOGOUT_STRING [OTRLanguageManager translatedString: EN_LOGOUT_STRING]
#define LOGIN_STRING [OTRLanguageManager translatedString: EN_LOGIN_STRING]
#define LOGOUT_FROM_AIM_STRING [OTRLanguageManager translatedString: EN_LOGOUT_FROM_AIM_STRING]
#define LOGOUT_FROM_XMPP_STRING [OTRLanguageManager translatedString: EN_LOGOUT_FROM_XMPP_STRING]
#define DELETE_ACCOUNT_TITLE_STRING [OTRLanguageManager translatedString: EN_DELETE_ACCOUNT_TITLE_STRING]
#define DELETE_ACCOUNT_MESSAGE_STRING [OTRLanguageManager translatedString: EN_DELETE_ACCOUNT_MESSAGE_STRING]
#define NO_ACCOUNT_SAVED_STRING [OTRLanguageManager translatedString: EN_NO_ACCOUNT_SAVED_STRING]
#define ATTRIBUTION_STRING [OTRLanguageManager translatedString: EN_ATTRIBUTION_STRING]
#define SOURCE_STRING [OTRLanguageManager translatedString: EN_SOURCE_STRING]
#define CONTRIBUTE_TRANSLATION_STRING [OTRLanguageManager translatedString: EN_CONTRIBUTE_TRANSLATION_STRING]
#define PROJECT_HOMEPAGE_STRING [OTRLanguageManager translatedString: EN_PROJECT_HOMEPAGE_STRING]
#define VERSION_STRING [OTRLanguageManager translatedString: EN_VERSION_STRING]
#define USERNAME_STRING [OTRLanguageManager translatedString: EN_USERNAME_STRING]
#define PASSWORD_STRING [OTRLanguageManager translatedString: EN_PASSWORD_STRING]
#define DOMAIN_STRING [OTRLanguageManager translatedString: EN_DOMAIN_STRING]
#define LOGIN_TO_STRING [OTRLanguageManager translatedString: EN_LOGIN_TO_STRING]
#define REMEMBER_USERNAME_STRING [OTRLanguageManager translatedString: EN_REMEMBER_USERNAME_STRING]
#define REMEMBER_PASSWORD_STRING [OTRLanguageManager translatedString: EN_REMEMBER_PASSWORD_STRING]
#define OPTIONAL_STRING [OTRLanguageManager translatedString: EN_OPTIONAL_STRING]
#define FACEBOOK_HELP_STRING [OTRLanguageManager translatedString: EN_FACEBOOK_HELP_STRING]
#define CRITTERCISM_TITLE_STRING [OTRLanguageManager translatedString: EN_CRITTERCISM_TITLE_STRING]
#define CRITTERCISM_DESCRIPTION_STRING [OTRLanguageManager translatedString: EN_CRITTERCISM_DESCRIPTION_STRING]
#define OTHER_STRING [OTRLanguageManager translatedString: EN_OTHER_STRING]
#define ALLOW_SELF_SIGNED_CERTIFICATES_STRING [OTRLanguageManager translatedString: EN_ALLOW_SELF_SIGNED_CERTIFICATES_STRING]
#define ALLOW_SSL_HOSTNAME_MISMATCH_STRING [OTRLanguageManager translatedString: EN_ALLOW_SSL_HOSTNAME_MISMATCH_STRING]
#define SECURITY_WARNING_DESCRIPTION_STRING [OTRLanguageManager translatedString: EN_SECURITY_WARNING_DESCRIPTION_STRING]
#define DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING [OTRLanguageManager translatedString: EN_DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING]
#define DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING [OTRLanguageManager translatedString: EN_DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING]
#define FONT_SIZE_STRING [OTRLanguageManager translatedString: EN_FONT_SIZE_STRING]
#define FONT_SIZE_DESCRIPTION_STRING [OTRLanguageManager translatedString: EN_FONT_SIZE_DESCRIPTION_STRING]
#define DISCONNECTION_WARNING_TITLE_STRING [OTRLanguageManager translatedString: EN_DISCONNECTION_WARNING_TITLE_STRING]
#define DISCONNECTION_WARNING_DESC_STRING [OTRLanguageManager translatedString: EN_DISCONNECTION_WARNING_DESC_STRING]
#define SETTINGS_STRING [OTRLanguageManager translatedString: EN_SETTINGS_STRING]
#define SHARE_STRING [OTRLanguageManager translatedString: EN_SHARE_STRING]
#define NOT_AVAILABLE_STRING [OTRLanguageManager translatedString: EN_NOT_AVAILABLE_STRING]
#define SHARE_MESSAGE_STRING [OTRLanguageManager translatedString: EN_SHARE_MESSAGE_STRING]
#define CONNECTED_STRING [OTRLanguageManager translatedString: EN_CONNECTED_STRING]
#define SEND_FEEDBACK_STRING [OTRLanguageManager translatedString: EN_SEND_FEEDBACK_STRING]
#define LANGUAGE_STRING [OTRLanguageManager translatedString: EN_LANGUAGE_STRING]
#define LANGUAGE_ALERT_TITLE_STRING [OTRLanguageManager translatedString: EN_LANGUAGE_ALERT_TITLE_STRING]
#define LANGUAGE_ALERT_MESSAGE_STRING [OTRLanguageManager translatedString: EN_LANGUAGE_ALERT_MESSAGE_STRING]
#define SAVE_STRING [OTRLanguageManager translatedString: EN_SAVE_STRING]
#define NEW_STRING [OTRLanguageManager translatedString: EN_NEW_STRING]
#define OLD_STRING [OTRLanguageManager translatedString: EN_OLD_STRING]
#define DONE_STRING [OTRLanguageManager translatedString: EN_DONE_STRING]
#define QR_CODE_INSTRUCTIONS_STRING [OTRLanguageManager translatedString: EN_QR_CODE_INSTRUCTIONS_STRING]
#define EXPIRATION_STRING [OTRLanguageManager translatedString: EN_EXPIRATION_STRING]
#define READ_STRING [OTRLanguageManager translatedString: EN_READ_STRING]
#define NEW_ACCOUNT_STRING [OTRLanguageManager translatedString: EN_NEW_ACCOUNT_STRING]
#define AIM_STRING [OTRLanguageManager translatedString: EN_AIM_STRING]
#define GOOGLE_TALK_STRING [OTRLanguageManager translatedString: EN_GOOGLE_TALK_STRING]
#define FACEBOOK_STRING [OTRLanguageManager translatedString: EN_FACEBOOK_STRING]
#define JABBER_STRING [OTRLanguageManager translatedString: EN_JABBER_STRING]
#define MESSAGE_PLACEHOLDER_STRING [OTRLanguageManager translatedString: EN_MESSAGE_PLACEHOLDER_STRING]
#define DELIVERED_STRING [OTRLanguageManager translatedString: EN_DELIVERED_STRING]
#define DONATE_STRING [OTRLanguageManager translatedString: EN_DONATE_STRING]
#define DONATE_MESSAGE_STRING [OTRLanguageManager translatedString: EN_DONATE_MESSAGE_STRING]
#define EXTENDED_AWAY_STRING [OTRLanguageManager translatedString: EN_EXTENDED_AWAY_STRING]
#define DO_NOT_DISTURB_STRING [OTRLanguageManager translatedString: EN_DO_NOT_DISTURB_STRING]
#define PENDING_APPROVAL_STRING [OTRLanguageManager translatedString: EN_PENDING_APPROVAL_STRING]
#define DEFAULT_BUDDY_GROUP_STRING [OTRLanguageManager translatedString: EN_DEFAULT_BUDDY_GROUP_STRING]
#define EMAIL_STRING [OTRLanguageManager translatedString: EN_EMAIL_STRING]
#define NAME_STRING [OTRLanguageManager translatedString: EN_NAME_STRING]
#define ACCOUNT_STRING [OTRLanguageManager translatedString: EN_ACCOUNT_STRING]
#define GROUP_STRING [OTRLanguageManager translatedString: EN_GROUP_STRING]
#define GROUPS_STRING [OTRLanguageManager translatedString: EN_GROUPS_STRING]
#define REMOVE_STRING [OTRLanguageManager translatedString: EN_REMOVE_STRING]
#define BLOCK_STRING [OTRLanguageManager translatedString: EN_BLOCK_STRING]
#define BLOCK_AND_REMOVE_STRING [OTRLanguageManager translatedString: EN_BLOCK_AND_REMOVE_STRING]
#define ADD_BUDDY_STRING [OTRLanguageManager translatedString: EN_ADD_BUDDY_STRING]
#define BUDDY_INFO_STRING [OTRLanguageManager translatedString: EN_BUDDY_INFO_STRING]

#define LOC_BUDDY_LIST_STRING NSLocalizedString(EN_BUDDY_LIST_STRING , @"Title for the buddy list tab")
#define LOC_CONVERSATIONS_STRING NSLocalizedString(EN_CONVERSATIONS_STRING , @"Title for the conversations tab")
#define LOC_ACCOUNTS_STRING NSLocalizedString(EN_ACCOUNTS_STRING , @"Title for the accounts tab")
#define LOC_ABOUT_STRING NSLocalizedString(EN_ABOUT_STRING , @"Title for the about page")
#define LOC_CHAT_STRING NSLocalizedString(EN_CHAT_STRING , @"Title for chat view")
#define LOC_CANCEL_STRING NSLocalizedString(EN_CANCEL_STRING , @"Cancel an alert window")
#define LOC_INITIATE_ENCRYPTED_CHAT_STRING NSLocalizedString(EN_INITIATE_ENCRYPTED_CHAT_STRING , @"Shown when starting an encrypted chat session")
#define LOC_CANCEL_ENCRYPTED_CHAT_STRING NSLocalizedString(EN_CANCEL_ENCRYPTED_CHAT_STRING , @"Shown when ending an encrypted chat session")
#define LOC_VERIFY_STRING NSLocalizedString(EN_VERIFY_STRING , @"Shown when verifying fingerprints")
#define LOC_VERIFIED_STRING NSLocalizedString(EN_VERIFIED_STRING , @"Shown when verifying fingerprints")
#define LOC_NOT_VERIFIED_STRING NSLocalizedString(EN_NOT_VERIFIED_STRING , @"Not Verfied or cancle verified")
#define LOC_VERIFY_LATER_STRING NSLocalizedString(EN_VERIFY_LATER_STRING , @"Shown when verifying fingerprings")
#define LOC_CLEAR_CHAT_HISTORY_STRING NSLocalizedString(EN_CLEAR_CHAT_HISTORY_STRING , @"String shown in dialog for removing chat history")
#define LOC_SEND_STRING NSLocalizedString(EN_SEND_STRING , @"For sending a message")
#define LOC_OK_STRING NSLocalizedString(EN_OK_STRING , @"Accept the dialog")
#define LOC_RECENT_STRING NSLocalizedString(EN_RECENT_STRING , @"Title for header of Buddy list view with Recent Buddies")
#define LOC_YOUR_FINGERPRINT_STRING NSLocalizedString(EN_YOUR_FINGERPRINT_STRING , @"your fingerprint")
#define LOC_THEIR_FINGERPRINT_STRING NSLocalizedString(EN_THEIR_FINGERPRINT_STRING , @"the alleged fingerprint of their other person")
#define LOC_SECURE_CONVERSATION_STRING NSLocalizedString(EN_SECURE_CONVERSATION_STRING , @"Inform user that they must be secure their conversation before doing that action")
#define LOC_VERIFY_FINGERPRINT_STRING NSLocalizedString(EN_VERIFY_FINGERPRINT_STRING , @"Title of the dialog for fingerprint verification")
#define LOC_CHAT_INSTRUCTIONS_LABEL_STRING NSLocalizedString(EN_CHAT_INSTRUCTIONS_LABEL_STRING , @"Instructions on how to start using the program")
#define LOC_OPEN_IN_SAFARI_STRING NSLocalizedString(EN_OPEN_IN_SAFARI_STRING , @"Shown when trying to open a link, asking if they want to switch to Safari to view it")
#define LOC_DISCONNECTED_TITLE_STRING NSLocalizedString(EN_DISCONNECTED_TITLE_STRING , @"Title of alert when user is disconnected from protocol")
#define LOC_DISCONNECTED_MESSAGE_STRING NSLocalizedString(EN_DISCONNECTED_MESSAGE_STRING , @"Message shown when user is disconnected")
#define LOC_DISCONNECTION_WARNING_STRING NSLocalizedString(EN_DISCONNECTION_WARNING_STRING , @"Warn user that conversation will be deleted after leaving it")
#define LOC_CONVERSATION_NOT_SECURE_WARNING_STRING NSLocalizedString(EN_CONVERSATION_NOT_SECURE_WARNING_STRING , @"Warn user that the current chat is not secure")
#define LOC_CONVERSATION_NO_LONGER_SECURE_STRING NSLocalizedString(EN_CONVERSATION_NO_LONGER_SECURE_STRING , @"Warn user that the current chat is no longer secure")
#define LOC_CONVERSATION_SECURE_WARNING_STRING NSLocalizedString(EN_CONVERSATION_SECURE_WARNING_STRING , @"Warns user that the current chat is secure")
#define LOC_CONVERSATION_SECURE_AND_VERIFIED_WARNING_STRING NSLocalizedString(EN_CONVERSATION_SECURE_AND_VERIFIED_WARNING_STRING , @"Warns user that the current chat is secure and verified")
#define LOC_CHAT_STATE_ACTIVE_STRING NSLocalizedString(EN_CHAT_STATE_ACTIVE_STRING , @"String to be displayed when a buddy is Active")
#define LOC_CHAT_STATE_COMPOSING_STRING NSLocalizedString(EN_CHAT_STATE_COMPOSING_STRING , @"String to be displayed when a buddy is currently composing a message")
#define LOC_CHAT_STATE_PAUSED_STRING NSLocalizedString(EN_CHAT_STATE_PAUSED_STRING , @"String to be displayed when a buddy has stopped composing and text has been entered")
#define LOC_CHAT_STATE_INACTVIE_STRING NSLocalizedString(EN_CHAT_STATE_INACTVIE_STRING , @"String to be displayed when a budy has become inactive")
#define LOC_CHAT_STATE_GONE_STRING NSLocalizedString(EN_CHAT_STATE_GONE_STRING , @"String to be displayed when a buddy is inactive for an extended period of time")
#define LOC_IGNORE_STRING NSLocalizedString(EN_IGNORE_STRING , @"Ignore an incoming message")
#define LOC_REPLY_STRING NSLocalizedString(EN_REPLY_STRING , @"Reply to an incoming message")
#define LOC_OFFLINE_STRING NSLocalizedString(EN_OFFLINE_STRING , @"Label in buddylist for users that are offline")
#define LOC_AWAY_STRING NSLocalizedString(EN_AWAY_STRING , @"Label in buddylist for users that are away")
#define LOC_AVAILABLE_STRING NSLocalizedString(EN_AVAILABLE_STRING , @"Label in buddylist for users that are available")
#define LOC_OFFLINE_MESSAGE_STRING NSLocalizedString(EN_OFFLINE_MESSAGE_STRING , @"Message shown inline for users that are offline")
#define LOC_AWAY_MESSAGE_STRING NSLocalizedString(EN_AWAY_MESSAGE_STRING , @"Message shown inline for users that are away")
#define LOC_AVAILABLE_MESSAGE_STRING NSLocalizedString(EN_AVAILABLE_MESSAGE_STRING , @"Message shown inline for users that are available")
#define LOC_SECURITY_WARNING_STRING NSLocalizedString(EN_SECURITY_WARNING_STRING , @"Title of alert box warning about security issues")
#define LOC_AGREE_STRING NSLocalizedString(EN_AGREE_STRING , @"Agree to EULA")
#define LOC_DISAGREE_STRING NSLocalizedString(EN_DISAGREE_STRING , @"Disagree with EULA")
#define LOC_ERROR_STRING NSLocalizedString(EN_ERROR_STRING , @"Title of error message popup box")
#define LOC_OSCAR_FAIL_STRING NSLocalizedString(EN_OSCAR_FAIL_STRING , @"Authentication failed, tell user to try again")
#define LOC_XMPP_FAIL_STRING NSLocalizedString(EN_XMPP_FAIL_STRING , @"Message when cannot connect to XMPP server")
#define LOC_XMPP_PORT_FAIL_STRING NSLocalizedString(EN_XMPP_PORT_FAIL_STRING , @"Message when port is changed but domain not set")
#define LOC_LOGGING_IN_STRING NSLocalizedString(EN_LOGGING_IN_STRING , @"shown during the login proceess")
#define LOC_USER_PASS_BLANK_STRING NSLocalizedString(EN_USER_PASS_BLANK_STRING , @"error message shown when user doesnt fill in a username or password")
#define LOC_BASIC_STRING NSLocalizedString(EN_BASIC_STRING , @"string to describe basic set of settings")
#define LOC_ADVANCED_STRING NSLocalizedString(EN_ADVANCED_STRING , @"stirng to describe advanced set of settings")
#define LOC_SSL_MISMATCH_STRING NSLocalizedString(EN_SSL_MISMATCH_STRING , @"stirng for settings to allow ssl mismatch")
#define LOC_SELF_SIGNED_SSL_STRING NSLocalizedString(EN_SELF_SIGNED_SSL_STRING , @"string for settings to allow self signed ssl stirng")
#define LOC_PORT_STRING NSLocalizedString(EN_PORT_STRING , @"Label for port number field for connecting to service")
#define LOC_GOOGLE_TALK_EXAMPLE_STRING NSLocalizedString(EN_GOOGLE_TALK_EXAMPLE_STRING , @"example of a google talk account")
#define LOC_REQUIRED_STRING NSLocalizedString(EN_REQUIRED_STRING , @"String to let user know a certain field like a password is required to create an account")
#define LOC_SEND_DELIVERY_RECEIPT_STRING NSLocalizedString(EN_SEND_DELIVERY_RECEIPT_STRING , @"String in login settings asking to send delivery receipts")
#define LOC_SEND_TYPING_NOTIFICATION_STRING NSLocalizedString(EN_SEND_TYPING_NOTIFICATION_STRING , @"Stirng in login settings asking to send typing notification")
#define LOC_LOGOUT_STRING NSLocalizedString(EN_LOGOUT_STRING , @"log out from account")
#define LOC_LOGIN_STRING NSLocalizedString(EN_LOGIN_STRING , @"log in to account")
#define LOC_LOGOUT_FROM_AIM_STRING NSLocalizedString(EN_LOGOUT_FROM_AIM_STRING , @"Ask user if they want to logout of OSCAR")
#define LOC_LOGOUT_FROM_XMPP_STRING NSLocalizedString(EN_LOGOUT_FROM_XMPP_STRING , @"ask user if they want to log out of xmpp")
#define LOC_DELETE_ACCOUNT_TITLE_STRING NSLocalizedString(EN_DELETE_ACCOUNT_TITLE_STRING , @"Ask user if they want to delete the stored account information")
#define LOC_DELETE_ACCOUNT_MESSAGE_STRING NSLocalizedString(EN_DELETE_ACCOUNT_MESSAGE_STRING , @"Ask user if they want to delete the stored account information")
#define LOC_NO_ACCOUNT_SAVED_STRING NSLocalizedString(EN_NO_ACCOUNT_SAVED_STRING , @"Message infomring user that there are no accounts currently saved")
#define LOC_ATTRIBUTION_STRING NSLocalizedString(EN_ATTRIBUTION_STRING , @"for attribution of other projects")
#define LOC_SOURCE_STRING NSLocalizedString(EN_SOURCE_STRING , @"let users know source is on Github")
#define LOC_CONTRIBUTE_TRANSLATION_STRING NSLocalizedString(EN_CONTRIBUTE_TRANSLATION_STRING , @"label for a link to contribute a new translation")
#define LOC_PROJECT_HOMEPAGE_STRING NSLocalizedString(EN_PROJECT_HOMEPAGE_STRING , @"label for link to ChatSecure project website")
#define LOC_VERSION_STRING NSLocalizedString(EN_VERSION_STRING , @"when displaying version numbers such as 1.0.0")
#define LOC_USERNAME_STRING NSLocalizedString(EN_USERNAME_STRING , @"Label text for username field on login screen")
#define LOC_PASSWORD_STRING NSLocalizedString(EN_PASSWORD_STRING , @"Label text for password field on login screen")
#define LOC_DOMAIN_STRING NSLocalizedString(EN_DOMAIN_STRING , @"Label text for domain field on login scree")
#define LOC_LOGIN_TO_STRING NSLocalizedString(EN_LOGIN_TO_STRING , @"Label for button describing which protocol you're logging into, will be followed by a protocol such as XMPP or AIM during layout")
#define LOC_REMEMBER_USERNAME_STRING NSLocalizedString(EN_REMEMBER_USERNAME_STRING , @"label for switch for whether or not we should save their username between launches")
#define LOC_REMEMBER_PASSWORD_STRING NSLocalizedString(EN_REMEMBER_PASSWORD_STRING , @"label for switch for whether or not we should save their password between launches")
#define LOC_OPTIONAL_STRING NSLocalizedString(EN_OPTIONAL_STRING , @"Hint text for domain field telling user this field is not required")
#define LOC_FACEBOOK_HELP_STRING NSLocalizedString(EN_FACEBOOK_HELP_STRING , @"Text that makes it clear which username to use")
#define LOC_CRITTERCISM_TITLE_STRING NSLocalizedString(EN_CRITTERCISM_TITLE_STRING , @"Title for crash reports settings switch")
#define LOC_CRITTERCISM_DESCRIPTION_STRING NSLocalizedString(EN_CRITTERCISM_DESCRIPTION_STRING , @"Description for crash reports settings switch")
#define LOC_OTHER_STRING NSLocalizedString(EN_OTHER_STRING , @"Title for other miscellaneous settings group")
#define LOC_ALLOW_SELF_SIGNED_CERTIFICATES_STRING NSLocalizedString(EN_ALLOW_SELF_SIGNED_CERTIFICATES_STRING , @"Title for settings cell on whether or not the XMPP library should allow self-signed SSL certificates")
#define LOC_ALLOW_SSL_HOSTNAME_MISMATCH_STRING NSLocalizedString(EN_ALLOW_SSL_HOSTNAME_MISMATCH_STRING , @"Title for settings cell on whether or not the XMPP library should allow SSL hostname mismatch")
#define LOC_SECURITY_WARNING_DESCRIPTION_STRING NSLocalizedString(EN_SECURITY_WARNING_DESCRIPTION_STRING , @"Cell description text that warns users that enabling that option may reduce their security.")
#define LOC_DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING NSLocalizedString(EN_DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING , @"Title for automatic conversation deletion setting")
#define LOC_DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING NSLocalizedString(EN_DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING , @"Description for automatic conversation deletion")
#define LOC_FONT_SIZE_STRING NSLocalizedString(EN_FONT_SIZE_STRING , @"Size for the font in the chat screen")
#define LOC_FONT_SIZE_DESCRIPTION_STRING NSLocalizedString(EN_FONT_SIZE_DESCRIPTION_STRING , @"description for what the font size setting affects")
#define LOC_DISCONNECTION_WARNING_TITLE_STRING NSLocalizedString(EN_DISCONNECTION_WARNING_TITLE_STRING , @"Title for setting about showing a warning before disconnection")
#define LOC_DISCONNECTION_WARNING_DESC_STRING NSLocalizedString(EN_DISCONNECTION_WARNING_DESC_STRING , @"Description for disconnection warning setting")
#define LOC_DEFAULT_LANGUAGE_STRING NSLocalizedString(EN_DEFAULT_LANGUAGE_STRING , @"default string to revert to normal language behaviour")
#define DEFAULT_LANGUAGE_STRING LOC_DEFAULT_LANGUAGE_STRING
#define LOC_SETTINGS_STRING NSLocalizedString(EN_SETTINGS_STRING , @"Title for the Settings screen")
#define LOC_SHARE_STRING NSLocalizedString(EN_SHARE_STRING , @"Title for sharing a link to the app")
#define LOC_NOT_AVAILABLE_STRING NSLocalizedString(EN_NOT_AVAILABLE_STRING , @"Shown when a feature is not available, for example SMS")
#define LOC_SHARE_MESSAGE_STRING NSLocalizedString(EN_SHARE_MESSAGE_STRING , @"Body of SMS or email when sharing a link to the app")
#define LOC_CONNECTED_STRING NSLocalizedString(EN_CONNECTED_STRING , @"Whether or not account is logged in")
#define LOC_SEND_FEEDBACK_STRING NSLocalizedString(EN_SEND_FEEDBACK_STRING , @"String on button to email feedback")
#define LOC_LANGUAGE_STRING NSLocalizedString(EN_LANGUAGE_STRING , @"string to bring up language selector")
#define LOC_LANGUAGE_ALERT_TITLE_STRING NSLocalizedString(EN_LANGUAGE_ALERT_TITLE_STRING , @"Stirng of title to alert user langague is change")
#define LOC_LANGUAGE_ALERT_MESSAGE_STRING NSLocalizedString(EN_LANGUAGE_ALERT_MESSAGE_STRING , @"Message alerting user that they need to return to the home screen and force close ChatSecure")
#define LOC_SAVE_STRING NSLocalizedString(EN_SAVE_STRING , @"Title for button for saving a setting")
#define LOC_NEW_STRING NSLocalizedString(EN_NEW_STRING , @"For a new settings value")
#define LOC_OLD_STRING NSLocalizedString(EN_OLD_STRING , @"For an old settings value")
#define LOC_DONE_STRING NSLocalizedString(EN_DONE_STRING , @"Title for button to press when user is finished")
#define LOC_QR_CODE_INSTRUCTIONS_STRING NSLocalizedString(EN_QR_CODE_INSTRUCTIONS_STRING , @"Instructions label text underneath QR code")
#define LOC_EXPIRATION_STRING NSLocalizedString(EN_EXPIRATION_STRING , @"Message displayed in Notification Manager when session will expire in one minute")
#define LOC_READ_STRING NSLocalizedString(EN_READ_STRING , @"Title for action button on alert dialog, used as a verb in the present tense")
#define LOC_NEW_ACCOUNT_STRING NSLocalizedString(EN_NEW_ACCOUNT_STRING , @"Title for New Account View")
#define LOC_AIM_STRING NSLocalizedString(EN_AIM_STRING , @"the name for AIM")
#define LOC_GOOGLE_TALK_STRING NSLocalizedString(EN_GOOGLE_TALK_STRING , @"the name for google talk")
#define LOC_FACEBOOK_STRING NSLocalizedString(EN_FACEBOOK_STRING , @"the name for facebook")
#define LOC_JABBER_STRING NSLocalizedString(EN_JABBER_STRING , @"the name for jabber, also include (XMPP) at the end")
#define LOC_MESSAGE_PLACEHOLDER_STRING NSLocalizedString(EN_MESSAGE_PLACEHOLDER_STRING , @"just the word as a placeholder for the message text field") 
#define LOC_DELIVERED_STRING NSLocalizedString(EN_DELIVERED_STRING , @"Shows in the chat view when a message has been delivered")
#define LOC_ALLOW_PLAIN_TEXT_AUTHENTICATION_STRING NSLocalizedString(EN_ALLOW_PLAIN_TEXT_AUTHENTICATION_STRING , @"Setting name for allowing authentication to happen in plain text or in the clear")
#define LOC_REQUIRE_TLS_STRING NSLocalizedString(EN_REQUIRE_TLS_STRING , @"Setting name for requiring a TLS connection")
#define LOC_DONATE_STRING NSLocalizedString(EN_DONATE_STRING, @"Title for donation link")
#define LOC_DONATE_MESSAGE_STRING NSLocalizedString(EN_DONATE_MESSAGE_STRING, @"Message shown when about to donate")
#define LOC_DO_NOT_DISTURB_STRING NSLocalizedString(EN_DO_NOT_DISTURB_STRING, @"Default message when a user status is set to do not disturb")
#define LOC_EXTENDED_AWAY_STRING NSLocalizedString(EN_EXTENDED_AWAY_STRING, @"Default message when a user status is set to extended away")
#define LOC_PENDING_APPROVAL_STRING NSLocalizedString(EN_PENDING_APPROVAL_STRING, @"String for xmpp buddies when adding buddy is pedning")
#define LOC_DEFAULT_BUDDY_GROUP_STRING NSLocalizedString(EN_DEFAULT_BUDDY_GROUP_STRING, @"Name for default buddy group")
#define LOC_EMAIL_STRING NSLocalizedString(EN_EMAIL_STRING,@"The string describing account name or email address for a buddy")
#define LOC_NAME_STRING NSLocalizedString(EN_NAME_STRING,@"The string describing a buddy's dispaly name")
#define LOC_ACCOUNT_STRING NSLocalizedString(EN_ACCOUNT_STRING,@"The string describing a buddy's account")
#define LOC_GROUP_STRING NSLocalizedString(EN_GROUP_STRING,@"The string describing a buddy's group")
#define LOC_GROUPS_STRING NSLocalizedString(EN_GROUPS_STRING,@"The string describing a buddy's groups ... plural")
#define LOC_REMOVE_STRING NSLocalizedString(EN_REMOVE_STRING,@"The String for a button to remove a buddy from the buddy list")
#define LOC_BLOCK_STRING NSLocalizedString(EN_BLOCK_STRING,@"The String for a button to block a buddy")
#define LOC_BLOCK_AND_REMOVE_STRING NSLocalizedString(EN_BLOCK_AND_REMOVE_STRING,@"The String for a buddy to block and remove a buddy from the buddy list")
#define LOC_ADD_BUDDY_STRING NSLocalizedString(EN_ADD_BUDDY_STRING,@"The title for the view to add a buddy")
#define LOC_BUDDY_INFO_STRING NSLocalizedString(EN_BUDDY_INFO_STRING,@"The title for the view that shows detailed buddy info")




