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

// GTMOAuth2WindowController
//
// This window controller for Mac handles sign-in via OAuth2 to Google or
// other services.
//
// This controller is not reusable; create a new instance of this controller
// every time the user will sign in.
//
// Sample usage for signing in to a Google service:
//
//  static NSString *const kKeychainItemName = @”My App: Google Plus”;
//  NSString *scope = @"https://www.googleapis.com/auth/plus.me";
//
//
//  GTMOAuth2WindowController *windowController;
//  windowController = [[[GTMOAuth2WindowController alloc] initWithScope:scope
//                                                              clientID:clientID
//                                                          clientSecret:clientSecret
//                                                      keychainItemName:kKeychainItemName
//                                                        resourceBundle:nil] autorelease];
//
//  [windowController signInSheetModalForWindow:mMainWindow
//                                     delegate:self
//                             finishedSelector:@selector(windowController:finishedWithAuth:error:)];
//
// The finished selector should have a signature matching this:
//
//  - (void)windowController:(GTMOAuth2WindowController *)windowController
//          finishedWithAuth:(GTMOAuth2Authentication *)auth
//                     error:(NSError *)error {
//    if (error != nil) {
//     // sign in failed
//    } else {
//     // sign in succeeded
//     //
//     // with the GTL library, pass the authentication to the service object,
//     // like
//     //   [[self contactService] setAuthorizer:auth];
//     //
//     // or use it to sign a request directly, like
//     //  BOOL isAuthorizing = [self authorizeRequest:request
//     //                                     delegate:self
//     //                            didFinishSelector:@selector(auth:finishedWithError:)];
//    }
//  }
//
// To sign in to services other than Google, use the longer init method,
// as shown in the sample application
//
// If the network connection is lost for more than 30 seconds while the sign-in
// html is displayed, the notification kGTLOAuthNetworkLost will be sent.

#if GTM_INCLUDE_OAUTH2 || !GDATA_REQUIRE_SERVICE_INCLUDES

#include <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// GTMHTTPFetcher.h brings in GTLDefines/GDataDefines
#import "GTMHTTPFetcher.h"

#import "GTMOAuth2SignIn.h"
#import "GTMOAuth2Authentication.h"
#import "GTMHTTPFetchHistory.h" // for GTMCookieStorage

@class GTMOAuth2SignIn;

@interface GTMOAuth2WindowController : NSWindowController {
 @private
  // IBOutlets
  NSButton *keychainCheckbox_;
  WebView *webView_;
  NSButton *webCloseButton_;
  NSButton *webBackButton_;

  // the object responsible for the sign-in networking sequence; it holds
  // onto the authentication object as well
  GTMOAuth2SignIn *signIn_;

  // the page request to load when awakeFromNib occurs
  NSURLRequest *initialRequest_;

  // local storage for WebKit cookies so they're not shared with Safari
  GTMCookieStorage *cookieStorage_;

  // the user we're calling back
  //
  // the delegate is retained only until the callback is invoked
  // or the sign-in is canceled
  id delegate_;
  SEL finishedSelector_;

#if NS_BLOCKS_AVAILABLE
  void (^completionBlock_)(GTMOAuth2Authentication *, NSError *);
#elif !__LP64__
  // placeholders: for 32-bit builds, keep the size of the object's ivar section
  // the same with and without blocks
#ifndef __clang_analyzer__
  id completionPlaceholder_;
#endif
#endif

  // flag allowing application to quit during display of sign-in sheet on 10.6
  // and later
  BOOL shouldAllowApplicationTermination_;

  // delegate method for handling URLs to be opened in external windows
  SEL externalRequestSelector_;

  BOOL isWindowShown_;

  // paranoid flag to ensure we only close once during the sign-in sequence
  BOOL hasDoneFinalRedirect_;

  // paranoid flag to ensure we only call the user back once
  BOOL hasCalledFinished_;

  // if non-nil, we display as a sheet on the specified window
  NSWindow *sheetModalForWindow_;

  // if non-empty, the name of the application and service used for the
  // keychain item
  NSString *keychainItemName_;

  // if non-nil, the html string to be displayed immediately upon opening
  // of the web view
  NSString *initialHTMLString_;

  // if true, we allow default WebView handling of cookies, so the
  // same user remains signed in each time the dialog is displayed
  BOOL shouldPersistUser_;

  // user-defined data
  id userData_;
  NSMutableDictionary *properties_;
}

// User interface elements
@property (nonatomic, assign) IBOutlet NSButton *keychainCheckbox;
@property (nonatomic, assign) IBOutlet WebView *webView;
@property (nonatomic, assign) IBOutlet NSButton *webCloseButton;
@property (nonatomic, assign) IBOutlet NSButton *webBackButton;

// The application and service name to use for saving the auth tokens
// to the keychain
@property (nonatomic, copy)   NSString *keychainItemName;

// If true, the sign-in will remember which user was last signed in
//
// Defaults to false, so showing the sign-in window will always ask for
// the username and password, rather than skip to the grant authorization
// page.  During development, it may be convenient to set this to true
// to speed up signing in.
@property (nonatomic, assign) BOOL shouldPersistUser;

// Optional html string displayed immediately upon opening the web view
//
// This string is visible just until the sign-in web page loads, and
// may be used for a "Loading..." type of message
@property (nonatomic, copy)   NSString *initialHTMLString;

// The default timeout for an unreachable network during display of the
// sign-in page is 30 seconds, after which the notification
// kGTLOAuthNetworkLost is sent; set this to 0 to have no timeout
@property (nonatomic, assign) NSTimeInterval networkLossTimeoutInterval;

// On 10.6 and later, the sheet can allow application termination by calling
// NSWindow's setPreventsApplicationTerminationWhenModal:
@property (nonatomic, assign) BOOL shouldAllowApplicationTermination;

// Selector for a delegate method to handle requests sent to an external
// browser.
//
// Selector should have a signature matching
// - (void)windowController:(GTMOAuth2WindowController *)controller
//             opensRequest:(NSURLRequest *)request;
//
// The controller's default behavior is to use NSWorkspace's openURL:
@property (nonatomic, assign) SEL externalRequestSelector;

// The underlying object to hold authentication tokens and authorize http
// requests
@property (nonatomic, retain, readonly) GTMOAuth2Authentication *authentication;

// The underlying object which performs the sign-in networking sequence
@property (nonatomic, retain, readonly) GTMOAuth2SignIn *signIn;

// Any arbitrary data object the user would like the controller to retain
@property (nonatomic, retain) id userData;

// Stored property values are retained for the convenience of the caller
- (void)setProperty:(id)obj forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;

@property (nonatomic, retain) NSDictionary *properties;

- (IBAction)closeWindow:(id)sender;

// Create a controller for authenticating to Google services
//
// scope is the requested scope of authorization
//   (like "http://www.google.com/m8/feeds")
//
// keychainItemName is used for storing the token on the keychain,
//   and is required for the "remember for later" checkbox to be shown;
//   keychainItemName should be like "My Application: Google Contacts"
//   (or set to nil if no persistent keychain storage is desired)
//
// resourceBundle may be nil if the window is in the main bundle's nib
#if !GTM_OAUTH2_SKIP_GOOGLE_SUPPORT
+ (id)controllerWithScope:(NSString *)scope
                 clientID:(NSString *)clientID
             clientSecret:(NSString *)clientSecret
         keychainItemName:(NSString *)keychainItemName  // may be nil
           resourceBundle:(NSBundle *)bundle;           // may be nil

- (id)initWithScope:(NSString *)scope
           clientID:(NSString *)clientID
       clientSecret:(NSString *)clientSecret
   keychainItemName:(NSString *)keychainItemName
     resourceBundle:(NSBundle *)bundle;
#endif

// Create a controller for authenticating to non-Google services, taking
//   explicit endpoint URLs and an authentication object
+ (id)controllerWithAuthentication:(GTMOAuth2Authentication *)auth
                  authorizationURL:(NSURL *)authorizationURL
                  keychainItemName:(NSString *)keychainItemName  // may be nil
                    resourceBundle:(NSBundle *)bundle;           // may be nil

// This is the designated initializer
- (id)initWithAuthentication:(GTMOAuth2Authentication *)auth
            authorizationURL:(NSURL *)authorizationURL
            keychainItemName:(NSString *)keychainItemName
              resourceBundle:(NSBundle *)bundle;

// Entry point to begin displaying the sign-in window
//
// the finished selector should have a signature matching
//  - (void)windowController:(GTMOAuth2WindowController *)windowController
//          finishedWithAuth:(GTMOAuth2Authentication *)auth
//                     error:(NSError *)error {
//
// Once the finished method has been invoked with no error, the auth object
// may be used to authorize requests (refreshing the access token, if necessary,
// and adding the auth header) like:
//
//     [authorizer authorizeRequest:myNSMutableURLRequest]
//                        delegate:self
//               didFinishSelector:@selector(auth:finishedWithError:)];
//
// or can be stored in a GTL service object like
//   GTLServiceGoogleContact *service = [self contactService];
//   [service setAuthorizer:auth];
//
// The delegate is retained only until the finished selector is invoked or
//   the sign-in is canceled
- (void)signInSheetModalForWindow:(NSWindow *)parentWindowOrNil
                         delegate:(id)delegate
                 finishedSelector:(SEL)finishedSelector;

#if NS_BLOCKS_AVAILABLE
- (void)signInSheetModalForWindow:(NSWindow *)parentWindowOrNil
                completionHandler:(void (^)(GTMOAuth2Authentication *auth, NSError *error))handler;
#endif

- (void)cancelSigningIn;

// Subclasses may override authNibName to specify a custom name
+ (NSString *)authNibName;

// apps may replace the sign-in class with their own subclass of it
+ (Class)signInClass;
+ (void)setSignInClass:(Class)theClass;

// Revocation of an authorized token from Google
#if !GTM_OAUTH2_SKIP_GOOGLE_SUPPORT
+ (void)revokeTokenForGoogleAuthentication:(GTMOAuth2Authentication *)auth;
#endif

// Keychain
//
// The keychain checkbox is shown if the keychain application service
// name (typically set in the initWithScope: method) is non-empty
//

// Create an authentication object for Google services from the access
// token and secret stored in the keychain; if no token is available, return
// an unauthorized auth object
#if !GTM_OAUTH2_SKIP_GOOGLE_SUPPORT
+ (GTMOAuth2Authentication *)authForGoogleFromKeychainForName:(NSString *)keychainItemName
                                                     clientID:(NSString *)clientID
                                                 clientSecret:(NSString *)clientSecret;
#endif

// Add tokens from the keychain, if available, to the authentication object
//
// returns YES if the authentication object was authorized from the keychain
+ (BOOL)authorizeFromKeychainForName:(NSString *)keychainItemName
                      authentication:(GTMOAuth2Authentication *)auth;

// Method for deleting the stored access token and secret, useful for "signing
// out"
+ (BOOL)removeAuthFromKeychainForName:(NSString *)keychainItemName;

// Method for saving the stored access token and secret; typically, this method
// is used only by the window controller
+ (BOOL)saveAuthToKeychainForName:(NSString *)keychainItemName
                   authentication:(GTMOAuth2Authentication *)auth;
@end

#endif // #if !TARGET_OS_IPHONE

#endif // #if GTM_INCLUDE_OAUTH2 || !GDATA_REQUIRE_SERVICE_INCLUDES
