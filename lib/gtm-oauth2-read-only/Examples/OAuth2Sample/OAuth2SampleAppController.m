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

#import "OAuth2SampleAppController.h"

@interface OAuth2SampleAppController ()
- (void)signInToGoogle;
- (void)signInToDailyMotion;

- (void)signOut;
- (BOOL)isSignedIn;

- (void)doAnAuthenticatedAPIFetch;
- (GTMOAuth2Authentication *)authForDailyMotion;

- (void)windowController:(GTMOAuth2WindowController *)windowController
        finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error;
- (void)updateUI;
- (void)setAuthentication:(GTMOAuth2Authentication *)auth;
- (void)signInFetchStateChanged:(NSNotification *)note;
- (void)signInNetworkLost:(NSNotification *)note;

- (void)saveClientIDValues;
- (void)loadClientIDValues;
@end

@implementation OAuth2SampleAppController

static NSString *const kKeychainItemName = @"OAuth2 Sample: Google Plus";

static NSString *const kDailyMotionKeychainItemName = @"OAuth2 Sample: DailyMotion";

static NSString *const kDailyMotionServiceName = @"DailyMotion";

// NSUserDefaults keys
static NSString *const kGoogleClientIDKey          = @"GoogleClientID";
static NSString *const kGoogleClientSecretKey      = @"GoogleClientSecret";
static NSString *const kDailyMotionClientIDKey     = @"DailyMotionClientID";
static NSString *const kDailyMotionClientSecretKey = @"DailyMotionClientSecret";

- (void)awakeFromNib {
  // Fill in the Client ID and Client Secret text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // First, we'll try to get the saved Google authentication, if any, from
  // the keychain

  // Normal applications will hardcode in their client ID and client secret,
  // but the sample app allows the user to enter them in a text field, and
  // saves them in the preferences
  NSString *clientID = [defaults stringForKey:kGoogleClientIDKey];
  NSString *clientSecret = [defaults stringForKey:kGoogleClientSecretKey];

  GTMOAuth2Authentication *auth = nil;

  if (clientID && clientSecret) {
    auth = [GTMOAuth2WindowController authForGoogleFromKeychainForName:kKeychainItemName
                                                              clientID:clientID
                                                          clientSecret:clientSecret];
  }

  if (auth.canAuthorize) {
    // Select the Google radio button
    [mRadioButtons selectCellWithTag:0];
  } else {
    // There is no saved Google authentication
    //
    // Perhaps we have a saved authorization for DailyMotion instead; try getting
    // that from the keychain

    clientID = [defaults stringForKey:kDailyMotionClientIDKey];
    clientSecret = [defaults stringForKey:kDailyMotionClientSecretKey];

    if (clientID && clientSecret) {
      auth = [self authForDailyMotion];
      if (auth) {
        auth.clientID = clientID;
        auth.clientSecret = clientSecret;

        BOOL didAuth = [GTMOAuth2WindowController authorizeFromKeychainForName:kDailyMotionKeychainItemName
                                                                authentication:auth];
        if (didAuth) {
          // select the DailyMotion radio button
          [mRadioButtons selectCellWithTag:1];
        }
      }
    }
  }

  // Save the authentication object, which holds the auth tokens and
  // the scope string used to obtain the token.  For Google services,
  // the auth object also holds the user's email address.
  [self setAuthentication:auth];

  // Update the client ID value text fields to match the radio button selection
  [self loadClientIDValues];

  // This is optional:
  //
  // We'll watch for the "hidden" fetches that occur to obtain tokens
  // during authentication, and start and stop our indeterminate progress
  // indicator during the fetches
  //
  // usually, these fetches are very brief
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(signInFetchStateChanged:)
             name:kGTMOAuth2FetchStarted
           object:nil];
  [nc addObserver:self
         selector:@selector(signInFetchStateChanged:)
             name:kGTMOAuth2FetchStopped
           object:nil];
  [nc addObserver:self
         selector:@selector(signInNetworkLost:)
             name:kGTMOAuth2NetworkLost
           object:nil];

  [self updateUI];
}

- (void)dealloc {
  [mAuth release];
  [super dealloc];
}

- (BOOL)isGoogleButtonSelected {
  int tag = [[mRadioButtons selectedCell] tag];
  return (tag == 0);
}

#pragma mark -

- (IBAction)APIConsoleClicked:(id)sender {
  NSURL *url = [NSURL URLWithString:@"https://code.google.com/apis/console"];
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)doAnAuthenticatedAPIFetchClicked:(id)sender {
  [self doAnAuthenticatedAPIFetch];
}

- (IBAction)expireNowClicked:(id)sender {
  NSDate *date = mAuth.expirationDate;
  if (date == nil) {
    NSBeep();
  } else {
    mAuth.expirationDate = [NSDate dateWithTimeIntervalSince1970:0];
    [self updateUI];
  }
}

- (IBAction)radioButtonClicked:(id)sender {
  [self loadClientIDValues];
}

- (BOOL)isSignedIn {
  BOOL isSignedIn = mAuth.canAuthorize;
  return isSignedIn;
}

- (IBAction)signInOutClicked:(id)sender {
  if (![self isSignedIn]) {
    // Sign in
    [mAPIResultTextView setString:@"Authenticating..."];

    if ([self isGoogleButtonSelected]) {
      [self signInToGoogle];
    } else {
      [self signInToDailyMotion];
    }
  } else {
    // Sign out
    [self signOut];

    [mAPIResultTextView setString:@""];
  }
  [self updateUI];
}

- (void)signOut {
  if ([mAuth.serviceProvider isEqual:kGTMOAuth2ServiceProviderGoogle]) {
    // Remove the token from Google's servers
    [GTMOAuth2WindowController revokeTokenForGoogleAuthentication:mAuth];
  }

  // Remove the stored Google authentication from the keychain, if any
  [GTMOAuth2WindowController removeAuthFromKeychainForName:kKeychainItemName];

  // Remove the stored DailyMotion authentication from the keychain, if any
  [GTMOAuth2WindowController removeAuthFromKeychainForName:kDailyMotionKeychainItemName];

  // Discard our retained authentication object
  [self setAuthentication:nil];

  [self updateUI];
}

- (void)signInToGoogle {
  [self signOut];

  // For Google APIs, the scope strings are available
  // in the service constant header files.
  NSString *scope = @"https://www.googleapis.com/auth/plus.me";

  // Typically, applications will hardcode the client ID and client secret
  // strings into the source code; they should not be user-editable or visible.
  NSString *clientID = [mClientIDField stringValue];
  NSString *clientSecret = [mClientSecretField stringValue];

  if ([clientID length] == 0 || [clientSecret length] == 0) {
    NSBeginAlertSheet(@"Error", nil, nil, nil, mMainWindow,
                      self, NULL, NULL, NULL,
                      @"The sample code requires a valid client ID"
                      " and client secret to sign in.");
    return;
  }

  // Display the autentication sheet
  GTMOAuth2WindowController *windowController;
  windowController = [GTMOAuth2WindowController controllerWithScope:scope
                                                           clientID:clientID
                                                       clientSecret:clientSecret
                                                   keychainItemName:kKeychainItemName
                                                     resourceBundle:nil];
  
  // During display of the sign-in window, loss and regain of network
  // connectivity will be reported with the notifications
  // kGTMOAuth2NetworkLost/kGTMOAuth2NetworkFound
  //
  // See the method signInNetworkLost: for an example of handling
  // the notification.

  // Optional: Google servers allow specification of the sign-in display
  // language as an additional "hl" parameter to the authorization URL,
  // using BCP 47 language codes.
  //
  // For this sample, we'll force English as the display language.
  NSDictionary *params = [NSDictionary dictionaryWithObject:@"en"
                                                     forKey:@"hl"];
  windowController.signIn.additionalAuthorizationParameters = params;

  // Optional: display some html briefly before the sign-in page loads
  NSString *html = @"<html><body><div align=center>Loading sign-in page...</div></body></html>";
  windowController.initialHTMLString = html;

  // Most applications will not want the dialog to remember the signed-in user
  // across multiple sign-ins, but the sample app allows it.
  windowController.shouldPersistUser = [mPersistUserCheckbox state];

  // By default, the controller will fetch the user's email, but not the rest of
  // the user's profile.  The full profile can be requested from Google's server
  // by setting this property before sign-in:
  //
  // windowController.signIn.shouldFetchGoogleUserProfile = YES;
  //
  // The profile will be available after sign-in as
  //
  //   NSDictionary *profile = windowController.signIn.userProfile;

  [windowController signInSheetModalForWindow:mMainWindow
                                     delegate:self
                             finishedSelector:@selector(windowController:finishedWithAuth:error:)];
}

- (GTMOAuth2Authentication *)authForDailyMotion {
  // http://www.dailymotion.com/doc/api/authentication.html
  NSURL *tokenURL = [NSURL URLWithString:@"https://api.dailymotion.com/oauth/token"];

  // We'll make up an arbitrary redirectURI.  The controller will watch for
  // the server to redirect the web view to this URI, but this URI will not be
  // loaded, so it need not be for any actual web page.
  NSString *redirectURI = @"http://www.google.com/OAuthCallback";

  NSString *clientID = [mClientIDField stringValue];
  NSString *clientSecret = [mClientSecretField stringValue];

  GTMOAuth2Authentication *auth;
  auth = [GTMOAuth2Authentication authenticationWithServiceProvider:kDailyMotionServiceName
                                                           tokenURL:tokenURL
                                                        redirectURI:redirectURI
                                                           clientID:clientID
                                                       clientSecret:clientSecret];
  return auth;
}

- (void)signInToDailyMotion {
  [self signOut];

  GTMOAuth2Authentication *auth = [self authForDailyMotion];
  auth.scope = @"read";

  if ([auth.clientID length] == 0 || [auth.clientSecret length] == 0) {
    NSBeginAlertSheet(@"Error", nil, nil, nil, mMainWindow,
                      self, NULL, NULL, NULL,
                      @"The sample code requires a valid client ID"
                      " and client secret to sign in.");
    return;
  }

  // display the autentication sheet
  NSURL *authURL = [NSURL URLWithString:@"https://api.dailymotion.com/oauth/authorize?display=popup"];
  
  GTMOAuth2WindowController *windowController;
  windowController = [GTMOAuth2WindowController controllerWithAuthentication:auth
                                                            authorizationURL:authURL
                                                            keychainItemName:kDailyMotionKeychainItemName
                                                              resourceBundle:nil];
  
  // optional: display some html briefly before the sign-in page loads
  NSString *html = @"<html><body><div align=center>Loading sign-in page...</div></body></html>";
  [windowController setInitialHTMLString:html];

  windowController.shouldPersistUser = [mPersistUserCheckbox state];

  [windowController signInSheetModalForWindow:mMainWindow
                                     delegate:self
                             finishedSelector:@selector(windowController:finishedWithAuth:error:)];
}

- (void)windowController:(GTMOAuth2WindowController *)windowController
        finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
  [mAPIResultTextView setString:@""];

  if (error != nil) {
    // Authentication failed (perhaps the user denied access, or closed the
    // window before granting access)
    NSString *errorStr = [error localizedDescription];

    NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
    if ([responseData length] > 0) {
      // Show the body of the server's authentication failure response
      errorStr = [[[NSString alloc] initWithData:responseData
                                        encoding:NSUTF8StringEncoding] autorelease];
    } else {
      NSString *str = [[error userInfo] objectForKey:kGTMOAuth2ErrorMessageKey];
      if ([str length] > 0) {
        errorStr = str;
      }
    }
    [mAPIResultTextView setString:errorStr];

    [self setAuthentication:nil];
  } else {
    // Authentication succeeded
    //
    // At this point, we either use the authentication object to explicitly
    // authorize requests, like
    //
    //  [auth authorizeRequest:myNSURLMutableRequest
    //       completionHandler:^(NSError *error) {
    //         if (error == nil) {
    //           // request here has been authorized
    //         }
    //       }];
    //
    // or store the authentication object into a fetcher or a Google API service
    // object like
    //
    //   [fetcher setAuthorizer:auth];

    // save the authentication object
    [self setAuthentication:auth];

    [mAPIResultTextView setString:@"Authentication succeeded"];

    // We can also access custom server response parameters here.
    //
    // For example, DailyMotion's token endpoint returns a uid value:
    //
    //   NSString *uid = [auth.parameters valueForKey:@"uid"];
  }

  [self updateUI];
}

#pragma mark -

- (void)doAnAuthenticatedAPIFetch {
  NSString *urlStr;
  if ([self isGoogleButtonSelected]) {
    // Google Plus feed
    urlStr = @"https://www.googleapis.com/plus/v1/people/me/activities/public";
  } else {
    // DailyMotion user favorites feed
    urlStr = @"https://api.dailymotion.com/videos/favorites";
  }

  [mAPIResultTextView setString:@"Doing an authenticated API fetch..."];
  [mAPIResultTextView display];

  NSURL *url = [NSURL URLWithString:urlStr];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [mAuth authorizeRequest:request
        completionHandler:^(NSError *error) {
          if (error) {
            [mAPIResultTextView setString:[error description]];
          } else {
            // Synchronous fetches like this are a really bad idea in Cocoa applications
            //
            // For a very easy async alternative, we could use GTMHTTPFetcher
            NSError *error = nil;
            NSURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
            if (data) {
              // API fetch succeeded
              NSString *str = [[[NSString alloc] initWithData:data
                                                     encoding:NSUTF8StringEncoding] autorelease];
              [mAPIResultTextView setString:str];
            } else {
              // Fetch failed
              [mAPIResultTextView setString:[error description]];
            }
          }

          // The access token may have changed
          [self updateUI];
        }];
}

#pragma mark -

- (void)signInFetchStateChanged:(NSNotification *)note {
  // This just lets the user know something is happening during the
  // sign-in sequence's "invisible" fetches to obtain tokens
  //
  // The fetcher is available as
  //   [[note userInfo] objectForKey:kGTMOAuth2FetcherKey]
  //
  // The type of token obtained is available on the start notification as
  //   [[note userInfo] objectForKey:kGTMOAuth2FetchTypeKey]
  //
  if ([[note name] isEqual:kGTMOAuth2FetchStarted]) {
    mAuthFetchersRunningCount++;
  } else if (mAuthFetchersRunningCount > 0) {
    mAuthFetchersRunningCount--;
  }

  if (mAuthFetchersRunningCount > 0) {
    [mSpinner startAnimation:self];
  } else {
    [mSpinner stopAnimation:self];
  }
}

- (void)signInNetworkLost:(NSNotification *)note {
  // The network dropped for 30 seconds
  //
  // We could alert the user and wait for notification that the network has
  // has returned, or just cancel the sign-in sheet, as shown here
  GTMOAuth2SignIn *signIn = [note object];
  GTMOAuth2WindowController *controller = [signIn delegate];
  [controller cancelSigningIn];
}

- (void)updateUI {
  // Update the text showing the signed-in state and the button title
  if ([self isSignedIn]) {
    // Signed in
    NSString *accessToken = mAuth.accessToken;
    NSString *refreshToken = mAuth.refreshToken;
    NSString *expiration = [mAuth.expirationDate description];
    NSString *email = mAuth.userEmail;
    NSString *serviceName = mAuth.serviceProvider;

    BOOL isVerified = [mAuth.userEmailIsVerified boolValue];
    if (!isVerified) {
      // Email address is not verified
      //
      // The email address is listed with the account info on the server, but
      // has not been confirmed as belonging to the owner of this account.
      email = [email stringByAppendingString:@" (unverified)"];
    }

    [mAccessTokenField setStringValue:(accessToken != nil ? accessToken : @"")];
    [mExpirationField setStringValue:(expiration != nil ? expiration : @"")];
    [mRefreshTokenField setStringValue:(refreshToken != nil ? refreshToken : @"")];
    [mUsernameField setStringValue:(email != nil ? email : @"")];
    [mServiceNameField setStringValue:(serviceName != nil ? serviceName : @"")];
    [mSignInOutButton setTitle:@"Sign Out"];
    [mDoAnAuthenticatedFetchButton setEnabled:YES];
    [mExpireNowButton setEnabled:YES];
  } else {
    // Signed out
    [mUsernameField setStringValue:@"-Not signed in-"];
    [mServiceNameField setStringValue:@""];
    [mAccessTokenField setStringValue:@"-No token-"];
    [mExpirationField setStringValue:@""];
    [mRefreshTokenField setStringValue:@""];
    [mSignInOutButton setTitle:@"Sign In..."];
    [mDoAnAuthenticatedFetchButton setEnabled:NO];
    [mExpireNowButton setEnabled:NO];
  }
}

- (void)setAuthentication:(GTMOAuth2Authentication *)auth {
  [mAuth autorelease];
  mAuth = [auth retain];
}

#pragma mark Client ID and Secret

//
// Normally an application will hardwire the client ID and client secret
// strings in the source code.  This sample app has to allow them to be
// entered by the developer, so we'll save them across runs into preferences.
//

- (void)saveClientIDValues {
  // Save the client ID and secret from the text fields into the prefs
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *clientID = [mClientIDField stringValue];
  NSString *clientSecret = [mClientSecretField stringValue];

  if ([self isGoogleButtonSelected]) {
    [defaults setObject:clientID forKey:kGoogleClientIDKey];
    [defaults setObject:clientSecret forKey:kGoogleClientSecretKey];
  } else {
    [defaults setObject:clientID forKey:kDailyMotionClientIDKey];
    [defaults setObject:clientSecret forKey:kDailyMotionClientSecretKey];
  }
}

- (void)loadClientIDValues {
  // Load the client ID and secret from the prefs into the text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *clientID, *clientSecret;

  if ([self isGoogleButtonSelected]) {
    clientID = [defaults stringForKey:kGoogleClientIDKey];
    clientSecret = [defaults stringForKey:kGoogleClientSecretKey];
  } else {
    clientID = [defaults stringForKey:kDailyMotionClientIDKey];
    clientSecret = [defaults stringForKey:kDailyMotionClientSecretKey];
  }

  [mClientIDField setStringValue:(clientID ? clientID : @"")];
  [mClientSecretField setStringValue:(clientSecret ? clientSecret : @"")];
}

- (void)controlTextDidChange:(NSNotification *)note {
  [self saveClientIDValues];
}

@end
