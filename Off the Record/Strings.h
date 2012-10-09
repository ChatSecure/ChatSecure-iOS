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

#define BUDDY_LIST_STRING NSLocalizedString(@"Buddy List", @"Title for the buddy list tab")
#define CONVERSATIONS_STRING NSLocalizedString(@"Conversations", @"Title for the conversations tab")
#define ACCOUNTS_STRING NSLocalizedString(@"Accounts", @"Title for the accounts tab")
#define ABOUT_STRING NSLocalizedString(@"About", @"Title for the about page")
#define CHAT_STRING NSLocalizedString(@"Chat", @"Title for chat view")
#define CANCEL_STRING NSLocalizedString(@"Cancel", @"Cancel an alert window")
#define INITIATE_ENCRYPTED_CHAT_STRING NSLocalizedString(@"Initiate Encrypted Chat", @"Shown when starting an encrypted chat session")
#define CANCEL_ENCRYPTED_CHAT_STRING NSLocalizedString(@"Cancel Encrypted Chat", @"Shown when ending an encrypted chat session")
#define VERIFY_STRING NSLocalizedString(@"Verify", @"Shown when verifying fingerprints")
#define CLEAR_CHAT_HISTORY_STRING NSLocalizedString(@"Clear Chat History", @"String shown in dialog for removing chat history")
#define SEND_STRING NSLocalizedString(@"Send", @"For sending a message")
#define OK_STRING NSLocalizedString(@"OK", @"Accept the dialog")
#define RECENT_STRING NSLocalizedString(@"Recent", @"Title for header of Buddy list view with Recent Buddies")

// Used in OTRChatViewController
#define YOUR_FINGERPRINT_STRING NSLocalizedString(@"Fingerprint for you", @"your fingerprint")
#define THEIR_FINGERPRINT_STRING NSLocalizedString(@"Purported fingerprint for", @"the alleged fingerprint of their other person")
#define SECURE_CONVERSATION_STRING NSLocalizedString(@"You must be in a secure conversation first.", @"Inform user that they must be secure their conversation before doing that action")
#define VERIFY_FINGERPRINT_STRING NSLocalizedString(@"Verify Fingerprint", "Title of the dialog for fingerprint verification")
#define CHAT_INSTRUCTIONS_LABEL_STRING NSLocalizedString(@"Log in on the Settings page (found on top right corner of buddy list) and then select a buddy from the Buddy List to start chatting.", @"Instructions on how to start using the program")
#define OPEN_IN_SAFARI_STRING NSLocalizedString(@"Open in Safari", @"Shown when trying to open a link, asking if they want to switch to Safari to view it")
#define DISCONNECTED_TITLE_STRING NSLocalizedString(@"Disconnected", @"Title of alert when user is disconnected from protocol")
#define DISCONNECTED_MESSAGE_STRING NSLocalizedString(@"You (%@) have disconnected.", @"Message shown when user is disconnected")
#define DISCONNECTION_WARNING_STRING NSLocalizedString(@"When you leave this conversation it will be deleted forever.", @"Warn user that conversation will be deleted after leaving it")
#define CONVERSATION_NOT_SECURE_WARNING_STRING NSLocalizedString(@"Warning: This chat is not encrypted", @"Warn user that the current chat is not secure")
#define CONVERSATION_NO_LONGER_SECURE_STRING NSLocalizedString(@"The conversation with %@ is no longer secure.", @"Warn user that the current chat is no longer secure")
#define CONVERSATION_SECURE_WARNING_STRING NSLocalizedString(@"This chat is secured",@"Warns user that the current chat is secure")
#define CONVERSATION_SECURE_AND_VERIFIED_WARNING_STRING NSLocalizedString(@"This chat is secured and verified",@"Warns user that the current chat is secure and verified")

#define CHAT_STATE_ACTIVE_STRING NSLocalizedString(@"Active",@"String to be displayed when a buddy is Active")
#define CHAT_STATE_COMPOSING_STRING NSLocalizedString(@"Typing",@"String to be displayed when a buddy is currently composing a message")
#define CHAT_STATE_PAUSED_STRING NSLocalizedString(@"Entered Text",@"String to be displayed when a buddy has stopped composing and text has been entered")
#define CHAT_STATE_INACTVIE_STRING NSLocalizedString(@"Inactive",@"String to be displayed when a budy has become inactive")
#define CHAT_STATE_GONE_STRING NSLocalizedString(@"Gone",@"String to be displayed when a buddy is inactive for an extended period of time")

// OTRBuddyListViewController
#define IGNORE_STRING NSLocalizedString(@"Ignore", @"Ignore an incoming message")
#define REPLY_STRING NSLocalizedString(@"Reply", @"Reply to an incoming message")
#define OFFLINE_STRING NSLocalizedString(@"Offline", @"Label in buddylist for users that are offline")
#define AWAY_STRING NSLocalizedString(@"Away", @"Label in buddylist for users that are away")
#define AVAILABLE_STRING NSLocalizedString(@"Available", "Label in buddylist for users that are available")
#define OFFLINE_MESSAGE_STRING NSLocalizedString(@"is now offline", @"Message shown inline for users that are offline")
#define AWAY_MESSAGE_STRING NSLocalizedString(@"is now away", @"Message shown inline for users that are away")
#define AVAILABLE_MESSAGE_STRING NSLocalizedString(@"is now available", "Message shown inline for users that are available")
#define SECURITY_WARNING_STRING NSLocalizedString(@"Security Warning", @"Title of alert box warning about security issues")
#define AGREE_STRING NSLocalizedString(@"Agree", "Agree to EULA")
#define DISAGREE_STRING NSLocalizedString(@"Disagree",@"Disagree with EULA")
#define EULA_WARNING_STRING NSLocalizedString(@"If you require true security, meet in person. This software, its dependencies, or the underlying OTR protocol could contain security issues. The full source code is available on Github but has not yet been audited by an independent security expert. Use at your own risk.", @"Text describing possible security risks")
#define EULA_BSD_STRING @"Modified BSD License:\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."

// OTRLoginViewController
#define ERROR_STRING NSLocalizedString(@"Error!", "Title of error message popup box")
#define OSCAR_FAIL_STRING NSLocalizedString(@"Failed to start authenticating. Please try again.", @"Authentication failed, tell user to try again")
#define XMPP_FAIL_STRING NSLocalizedString(@"Failed to connect to XMPP server. Please check your login credentials and internet connection and try again.", @"Message when cannot connect to XMPP server")
#define LOGGING_IN_STRING NSLocalizedString(@"Logging in...", @"shown during the login proceess")
#define USER_PASS_BLANK_STRING NSLocalizedString(@"You must enter a username and a password to login.", @"error message shown when user doesnt fill in a username or password")
#define BASIC_STRING NSLocalizedString(@"Basic", @"string to describe basic set of settings")
#define ADVANCED_STRING NSLocalizedString(@"Advanced", "stirng to describe advanced set of settings")
#define SSL_MISMATCH_STRING NSLocalizedString(@"SSL Hostname Mismatch",@"stirng for settings to allow ssl mismatch")
#define SELF_SIGNED_SSL_STRING NSLocalizedString(@"Self Signed SSL",@"string for settings to allow self signed ssl stirng")
#define PORT_STRING NSLocalizedString(@"Port", @"Label for port number field for connecting to service")
#define GOOGLE_TALK_EXAMPLE_STRING NSLocalizedString(@"user@gmail.com", @"example of a google talk account");
#define REQUIRED_STRING NSLocalizedString(@"Required",@"String to let user know a certain field like a password is required to create an account")

// OTRAccountsViewController
#define LOGOUT_STRING NSLocalizedString(@"Log Out", @"log out from account")
#define LOGIN_STRING NSLocalizedString(@"Log In", "log in to account")
#define LOGOUT_FROM_AIM_STRING NSLocalizedString(@"Logout from AIM?", "Ask user if they want to logout of AIM")
#define LOGOUT_FROM_XMPP_STRING NSLocalizedString(@"Logout from XMPP?", "ask user if they want to log out of xmpp")
#define DELETE_ACCOUNT_TITLE_STRING NSLocalizedString(@"Delete Account?", @"Ask user if they want to delete the stored account information")
#define DELETE_ACCOUNT_MESSAGE_STRING NSLocalizedString(@"Permanently delete", @"Ask user if they want to delete the stored account information")
#define NO_ACCOUNT_SAVED_STRING NSLocalizedString (@"No Saved Accounts", @"Message infomring user that there are no accounts currently saved")

// OTRAboutViewController
#define ATTRIBUTION_STRING NSLocalizedString(@"ChatSecure is brought to you by many open source projects", @"for attribution of other projects")
#define SOURCE_STRING NSLocalizedString(@"Check out the source here on Github", "let users know source is on Github")
#define CONTRIBUTE_TRANSLATION_STRING NSLocalizedString(@"Contribute a translation", @"label for a link to contribute a new translation")
#define PROJECT_HOMEPAGE_STRING NSLocalizedString(@"Project Homepage", @"label for link to ChatSecure project website")
#define VERSION_STRING NSLocalizedString(@"Version", @"when displaying version numbers such as 1.0.0")

// OTRLoginViewController
#define USERNAME_STRING NSLocalizedString(@"Username", @"Label text for username field on login screen")
#define PASSWORD_STRING NSLocalizedString(@"Password", @"Label text for password field on login screen")
#define DOMAIN_STRING NSLocalizedString(@"Domain", @"Label text for domain field on login scree")
#define LOGIN_TO_STRING NSLocalizedString(@"Login to", @"Label for button describing which protocol you're logging into, will be followed by a protocol such as XMPP or AIM during layout")
#define REMEMBER_USERNAME_STRING NSLocalizedString(@"Remember username", @"label for switch for whether or not we should save their username between launches")
#define REMEMBER_PASSWORD_STRING NSLocalizedString(@"Remember password", @"label for switch for whether or not we should save their password between launches")
#define OPTIONAL_STRING NSLocalizedString(@"Optional", @"Hint text for domain field telling user this field is not required")
#define FACEBOOK_HELP_STRING NSLocalizedString( @"Your Facebook username is not the email address that you use to login to Facebook",@"Text that makes it clear which username to use")


// OTRSettingsManager
#define CRITTERCISM_TITLE_STRING NSLocalizedString(@"Send Crash Reports", @"Title for crash reports settings switch")
#define CRITTERCISM_DESCRIPTION_STRING NSLocalizedString(@"Automatically send anonymous crash logs (opt-in)", @"Description for crash reports settings switch")
#define OTHER_STRING NSLocalizedString(@"Other", @"Title for other miscellaneous settings group")
#define ALLOW_SELF_SIGNED_CERTIFICATES_STRING NSLocalizedString(@"Self-Signed SSL", @"Title for settings cell on whether or not the XMPP library should allow self-signed SSL certificates")
#define ALLOW_SSL_HOSTNAME_MISMATCH_STRING NSLocalizedString(@"Hostname Mismatch", @"Title for settings cell on whether or not the XMPP library should allow SSL hostname mismatch")
#define SECURITY_WARNING_DESCRIPTION_STRING NSLocalizedString(@"Warning: Use with caution! This may reduce your security.", @"Cell description text that warns users that enabling that option may reduce their security.")
#define DELETE_CONVERSATIONS_ON_DISCONNECT_TITLE_STRING NSLocalizedString(@"Auto-delete", @"Title for automatic conversation deletion setting")
#define DELETE_CONVERSATIONS_ON_DISCONNECT_DESCRIPTION_STRING NSLocalizedString(@"Delete chats on disconnect", @"Description for automatic conversation deletion")
#define FONT_SIZE_STRING NSLocalizedString(@"Font Size", @"Size for the font in the chat screen")
#define FONT_SIZE_DESCRIPTION_STRING NSLocalizedString(@"Size for font in chat view", @"description for what the font size setting affects")
#define DISCONNECTION_WARNING_TITLE_STRING NSLocalizedString(@"Signout Warning", @"Title for setting about showing a warning before disconnection")
#define DISCONNECTION_WARNING_DESC_STRING NSLocalizedString(@"1 Minute Alert Before Disconnection", @"Description for disconnection warning setting")


// OTRSettingsViewController
#define SETTINGS_STRING NSLocalizedString(@"Settings", @"Title for the Settings screen")
#define SHARE_STRING NSLocalizedString(@"Share", @"Title for sharing a link to the app")
#define NOT_AVAILABLE_STRING NSLocalizedString(@"Not Available", @"Shown when a feature is not available, for example SMS")
#define SHARE_MESSAGE_STRING NSLocalizedString(@"Chat with me securely", @"Body of SMS or email when sharing a link to the app")
#define CONNECTED_STRING NSLocalizedString(@"Connected", @"Whether or not account is logged in")

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

// OTRNewAccountViewControler
#define NEW_ACCOUNT_STRING NSLocalizedString(@"New Account", @"Title for New Account View")

//OTRAccount
#define AIM_STRING NSLocalizedString(@"AOL Instant Messenger", "the name for AIM")
#define GOOGLE_TALK_STRING NSLocalizedString(@"Google Talk", "the name for google talk")
#define FACEBOOK_STRING NSLocalizedString(@"Facebook","the name for facebook")
#define JABBER_STRING NSLocalizedString(@"Jabber (XMPP)","the name for jabber, also include (XMPP) at the end")


