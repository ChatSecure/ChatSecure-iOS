/* Copyright (c) 2011 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Cocoa/Cocoa.h>

#import "GTMOAuth2WindowController.h"

@interface OAuth2SampleAppController : NSObject {
 @private
  IBOutlet NSWindow *mMainWindow;
  IBOutlet NSButton *mSignInOutButton;
  IBOutlet NSButton *mDoAnAuthenticatedFetchButton;
  IBOutlet NSButton *mPersistUserCheckbox;
  IBOutlet NSButton *mExpireNowButton;
  IBOutlet NSMatrix *mRadioButtons;
  IBOutlet NSTextField *mClientIDField;
  IBOutlet NSTextField *mClientSecretField;
  IBOutlet NSTextField *mUsernameField;
  IBOutlet NSTextField *mServiceNameField;
  IBOutlet NSTextField *mAccessTokenField;
  IBOutlet NSTextField *mExpirationField;
  IBOutlet NSTextField *mRefreshTokenField;
  IBOutlet NSProgressIndicator *mSpinner;
  IBOutlet NSTextView *mAPIResultTextView;

  GTMOAuth2Authentication *mAuth;

  NSUInteger mAuthFetchersRunningCount;
}

- (IBAction)signInOutClicked:(id)sender;

- (IBAction)radioButtonClicked:(id)sender;

- (IBAction)APIConsoleClicked:(id)sender;

- (IBAction)expireNowClicked:(id)sender;

- (IBAction)doAnAuthenticatedAPIFetchClicked:(id)sender;

@end
