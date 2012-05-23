//
//  Strings.h
//  Off the Record
//
//  Created by Chris Ballinger on 4/7/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#define BUDDY_LIST_STRING NSLocalizedString(@"Buddy List", @"Title for the buddy list tab")
#define CONVERSATIONS_STRING NSLocalizedString(@"Conversations", @"Title for the conversations tab")
#define ACCOUNTS_STRING NSLocalizedString(@"Accounts", @"Title for the accounts tab")
#define ABOUT_STRING NSLocalizedString(@"About", @"Title for the about page")
#define CHAT_STRING NSLocalizedString(@"Chat", @"Title for chat view")
#define CANCEL_STRING NSLocalizedString(@"Cancel", @"Cancel an alert window")
#define INITIATE_ENCRYPTED_CHAT_STRING NSLocalizedString(@"Initiate Encrypted Chat", @"Shown when starting an encrypted chat session")
#define VERIFY_STRING NSLocalizedString(@"Verify", @"Shown when verifying fingerprints")
#define SEND_STRING NSLocalizedString(@"Send", @"For sending a message")
#define OK_STRING NSLocalizedString(@"OK", @"Accept the dialog")

// Used in OTRChatViewController
#define YOUR_FINGERPRINT_STRING NSLocalizedString(@"Fingerprint for you", @"your fingerprint")
#define THEIR_FINGERPRINT_STRING NSLocalizedString(@"Purported fingerprint for", @"the alleged fingerprint of their other person")
#define SECURE_CONVERSATION_STRING NSLocalizedString(@"You must be in a secure conversation first.", @"Inform user that they must be secure their conversation before doing that action")
#define VERIFY_FINGERPRINT_STRING NSLocalizedString(@"Verify Fingerprint", "Title of the dialog for fingerprint verification")
#define CHAT_INSTRUCTIONS_LABEL_STRING NSLocalizedString(@"Log in on the Accounts tab and then select a buddy from the Buddy List to start chatting.", @"Instructions on how to start using the program")
#define OPEN_IN_SAFARI_STRING NSLocalizedString(@"Open in Safari", @"Shown when trying to open a link, asking if they want to switch to Safari to view it")
#define DISCONNECTED_TITLE_STRING NSLocalizedString(@"Disconnected", @"Title of alert when user is disconnected from protocol")
#define DISCONNECTED_MESSAGE_STRING NSLocalizedString(@"You have disconnected.", @"Message shown when user is disconnected")
#define DISCONNECTION_WARNING_STRING NSLocalizedString(@"When you leave this conversation it will be deleted forever.", @"Warn user that conversation will be deleted after leaving it")

// OTRBuddyListViewController
#define IGNORE_STRING NSLocalizedString(@"Ignore", @"Ignore an incoming message")
#define REPLY_STRING NSLocalizedString(@"Reply", @"Reply to an incoming message")
#define OFFLINE_STRING NSLocalizedString(@"Offline", @"Label in buddylist for users that are offline")
#define AWAY_STRING NSLocalizedString(@"Away", @"Label in buddylist for users that are away")
#define AVAILABLE_STRING NSLocalizedString(@"Available", "Label in buddylist for users that are available")

// OTRLoginViewController
#define ERROR_STRING NSLocalizedString(@"Error!", "Title of error message popup box")
#define OSCAR_FAIL_STRING NSLocalizedString(@"Failed to start authenticating. Please try again.", @"Authentication failed, tell user to try again")
#define XMPP_FAIL_STRING NSLocalizedString(@"Failed to connect to XMPP server. Please check your login credentials and internet connection and try again.", @"Message when cannot connect to XMPP server")
#define LOGGING_IN_STRING NSLocalizedString(@"Logging in...", @"shown during the login proceess")
#define USER_PASS_BLANK_STRING NSLocalizedString(@"You must enter a username and a password to login.", @"error message shown when user doesnt fill in a username or password")

// OTRAccountsViewController
#define AIM_STRING NSLocalizedString(@"AOL Instant Messenger", "the name for AIM")
#define XMPP_STRING NSLocalizedString(@"Google Talk (XMPP)", "the name for google talk, also include (XMPP) at the end")
#define LOGOUT_STRING NSLocalizedString(@"Log Out", @"log out from account")
#define LOGIN_STRING NSLocalizedString(@"Log In", "log in to account")
#define LOGOUT_FROM_AIM_STRING NSLocalizedString(@"Logout from AIM?", "Ask user if they want to logout of AIM")
#define LOGOUT_FROM_XMPP_STRING NSLocalizedString(@"Logout from XMPP?", "ask user if they want to log out of xmpp")

// OTRAboutViewController
#define ATTRIBUTION_STRING NSLocalizedString(@"ChatSecure is brought to you by many open source projects", @"for attribution of other projects")
#define SOURCE_STRING NSLocalizedString(@"Check out the source here on Github", "let users know source is on Github")
#define VERSION_STRING NSLocalizedString(@"Version", @"when displaying version numbers such as 1.0.0")

// OTRLoginViewController
#define USERNAME_STRING NSLocalizedString(@"Username", @"Label text for username field on login screen")
#define PASSWORD_STRING NSLocalizedString(@"Password", @"Label text for password field on login screen")
#define LOGIN_TO_STRING NSLocalizedString(@"Login to", @"Label for button describing which protocol you're logging into, will be followed by a protocol such as XMPP or AIM during layout")
#define REMEMBER_USERNAME_STRING NSLocalizedString(@"Remember username", @"label for switch for whether or not we should save their username between launches")

// OTRSettingsManager
#define CRITTERCISM_TITLE_STRING NSLocalizedString(@"Send Crash Reports", @"Title for crash reports settings switch")
#define CRITTERCISM_DESCRIPTION_STRING NSLocalizedString(@"Automatically send anonymous crash logs (opt-in)", @"Description for crash reports settings switch")
#define OTHER_STRING NSLocalizedString(@"Other", @"Title for other miscellaneous settings group")
#define ALLOW_SELF_SIGNED_CERTIFICATES_STRING NSLocalizedString(@"Self-Signed SSL", @"Title for settings cell on whether or not the XMPP library should allow self-signed SSL certificates")
#define ALLOW_SSL_HOSTNAME_MISMATCH_STRING NSLocalizedString(@"Hostname Mismatch", @"Title for settings cell on whether or not the XMPP library should allow SSL hostname mismatch")
#define SECURITY_WARNING_STRING NSLocalizedString(@"Warning: Use with caution! This may reduce your security.", @"Cell description text that warns users that enabling that option may reduce their security.")
#define DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING NSLocalizedString(@"Auto-delete", @"Title for automatic conversation deletion setting")
#define DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING NSLocalizedString(@"Delete chats on disconnect", @"Description for automatic conversation deletion")
#define FONT_SIZE_STRING NSLocalizedString(@"Font Size", @"Size for the font in the chat screen")
#define FONT_SIZE_DESCRIPTION_STRING NSLocalizedString(@"Size for font in chat view", @"description for what the font size setting affects")

// OTRSettingsViewController
#define SETTINGS_STRING NSLocalizedString(@"Settings", @"Title for the Settings screen")
#define SHARE_STRING NSLocalizedString(@"Share", @"Title for sharing a link to the app")
#define NOT_AVAILABLE_STRING NSLocalizedString(@"Not Available", @"Shown when a feature is not available, for example SMS")
#define SHARE_MESSAGE_STRING NSLocalizedString(@"Chat with me securely", @"Body of SMS or email when sharing a link to the app")

// OTRSettingsDetailViewController
#define SAVE_STRING NSLocalizedString(@"Save", "Title for button for saving a setting")
// OTRDoubleSettingViewController
#define NEW_STRING NSLocalizedString(@"New", "For a new settings value")
#define OLD_STRING NSLocalizedString(@"Old", "For an old settings value")

// OTRQRCodeViewController
#define DONE_STRING NSLocalizedString(@"Done", "Title for button to press when user is finished")
#define QR_CODE_INSTRUCTIONS_STRING NSLocalizedString(@"This QR Code contains a link to http://omniqrcode.com/q/chatsecure and will redirect to the App Store.", @"Instructions label text underneath QR code")

// OTRAppDelegate
#define EXPIRATION_STRING NSLocalizedString(@"Background session will expire in one minute.", @"Message displayed in Notification Manager when session will expire in one minute")
#define READ_STRING NSLocalizedString(@"Read", @"Title for action button on alert dialog, used as a verb in the present tense")