/* Copyright (c) 2013 Google Inc.
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

#if !STRIP_GTM_FETCH_LOGGING && !STRIP_GTM_HTTPLOGVIEWCONTROLLER

#import <UIKit/UIKit.h>

// GTMHTTPFetcherLogViewController allows browsing of GTMHTTPFetcher's logs on
// the iOS device.  Logging must have been enabled with
//
//   [GTMHTTPFetcher setLoggingEnabled:YES];
//
// A table will display one entry for each run of the app, with the most recent
// run's log listed first. A simple web view is used to browse the contents of
// an individual run's log.
//
// To use, push the view controller onto your app's navigation controller.
//
//  GTMHTTPFetcherLogViewController *logViewController =
//      [[[GTMHTTPFetcherLogViewController alloc] init] autorelease];
//  [navController pushViewController:logViewController
//                           animated:YES];
//
// Apps without a UINavigationController may use controllerWithTarget:selector:
// convenience method to make one. For example:
//
//    UINavigationController *nc =
//       [GTMHTTPFetcherLogViewController controllerWithTarget:self
//                                                    selector:@selector(logsDone:)];
//    [self presentViewController:nc animated:YES completion:NULL];
//
//  - (void)logsDone:(UINavigationController *)navController {
//    [self dismissViewControllerAnimated:YES completion:NULL];
//  }

@interface GTMHTTPFetcherLogViewController : UITableViewController

// This optional convenience method created a nav controller for use
// by apps that do not have a standard UINavigationController, as shown
// in the code snippet above.
//
// The selector should be for a method with a signature matching
//   - (void)logsDone:(UINavigationController *)navController
//
// The target and selector may be nil.
+ (UINavigationController *)controllerWithTarget:(id)target
                                        selector:(SEL)selector;
@end

#endif
