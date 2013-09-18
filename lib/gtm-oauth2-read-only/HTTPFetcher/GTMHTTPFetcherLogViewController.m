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

#if defined(__has_feature) && __has_feature(objc_arc)
#error "This file uses manual reference counting. Compile with -fno-objc-arc"
#endif

#import "GTMHTTPFetcherLogViewController.h"

#if !STRIP_GTM_FETCH_LOGGING && !STRIP_GTM_HTTPLOGVIEWCONTROLLER

#import <objc/runtime.h>

#import "GTMHTTPFetcher.h"
#import "GTMHTTPFetcherLogging.h"

static NSString *const kHTTPLogsCell = @"kGTMHTTPLogsCell";

// A minimal controller will be used to wrap a web view for displaying the
// log files.
@interface GTMHTTPFetcherLoggingWebViewController : UIViewController<UIWebViewDelegate>
- (id)initWithURL:(NSURL *)htmlURL title:(NSString *)title;
@end

#pragma mark - Table View Controller

@interface GTMHTTPFetcherLogViewController ()
@property (nonatomic, copy) void (^callbackBlock)(void);
@end

@implementation GTMHTTPFetcherLogViewController {
  NSArray *logsFolderURLs_;
}

@synthesize callbackBlock = callbackBlock_;

- (instancetype)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    self.title = @"HTTP Logs";

    // Find all folders containing logs.
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *logsFolderPath = [GTMHTTPFetcher loggingDirectory];
    NSString *processName = [GTMHTTPFetcher loggingProcessName];

    NSURL *logsURL = [NSURL fileURLWithPath:logsFolderPath];
    NSMutableArray *mutableURLs =
        [[fm contentsOfDirectoryAtURL:logsURL
           includingPropertiesForKeys:@[ NSURLCreationDateKey ]
                              options:0
                                error:&error] mutableCopy];

    // Remove non-log files that lack the process name prefix,
    // and remove the "newest" symlink.
    NSString *symlinkSuffix = [GTMHTTPFetcher symlinkNameSuffix];
    NSIndexSet *nonLogIndexes = [mutableURLs indexesOfObjectsPassingTest:
        ^BOOL(id obj, NSUInteger idx, BOOL *stop) {
      NSString *name = [obj lastPathComponent];
         return (![name hasPrefix:processName]
                 || [name hasSuffix:symlinkSuffix]);
    }];
    [mutableURLs removeObjectsAtIndexes:nonLogIndexes];

    // Sort to put the newest logs at the top of the list.
    [mutableURLs sortUsingComparator:^NSComparisonResult(NSURL *url1,
                                                         NSURL *url2) {
      NSDate *date1, *date2;
      [url1 getResourceValue:&date1 forKey:NSURLCreationDateKey error:NULL];
      [url2 getResourceValue:&date2 forKey:NSURLCreationDateKey error:NULL];
      return [date2 compare:date1];
    }];
    logsFolderURLs_ = mutableURLs;
  }
  return self;
}

- (void)dealloc {
  [logsFolderURLs_ release];
  [super dealloc];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Avoid silent failure if this was not added to a UINavigationController.
  //
  // The method +controllerWithTarget:selector: can be used to create a
  // temporary UINavigationController.
  NSAssert(self.navigationController != nil, @"Need a UINavigationController");
}

#pragma mark -

- (NSString *)shortenedNameForURL:(NSURL *)url {
  // Remove "Processname_log_" from the start of the file name.
  NSString *name = [url lastPathComponent];
  NSString *prefix = [GTMHTTPFetcher processNameLogPrefix];
  if ([name hasPrefix:prefix]) {
    name = [name substringFromIndex:[prefix length]];
  }
  return name;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return [logsFolderURLs_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kHTTPLogsCell];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:kHTTPLogsCell] autorelease];
    [cell.textLabel setAdjustsFontSizeToFitWidth:YES];
  }

  NSURL *url = [logsFolderURLs_ objectAtIndex:indexPath.row];
  cell.textLabel.text = [self shortenedNameForURL:url];

  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSURL *folderURL = [logsFolderURLs_ objectAtIndex:indexPath.row];
  NSString *htmlName = [GTMHTTPFetcher htmlFileName];
  NSURL *htmlURL = [folderURL URLByAppendingPathComponent:htmlName];

  // Show the webview controller.
  NSString *title = [self shortenedNameForURL:folderURL];
  UIViewController *webViewController =
      [[[GTMHTTPFetcherLoggingWebViewController alloc] initWithURL:htmlURL
                                                             title:title] autorelease];

  UINavigationController *navController = [self navigationController];
  [navController pushViewController:webViewController animated:YES];

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

+ (UINavigationController *)controllerWithTarget:(id)target
                                        selector:(SEL)selector {
  UINavigationController *navController =
      [[[UINavigationController alloc] init] autorelease];
  GTMHTTPFetcherLogViewController *logViewController =
      [[[GTMHTTPFetcherLogViewController alloc] init] autorelease];
  UIBarButtonItem *barButtonItem =
      [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                     target:logViewController
                                                     action:@selector(doneButtonClicked:)] autorelease];
  logViewController.navigationItem.leftBarButtonItem = barButtonItem;

  // Make a block to capture the callback and nav controller.
  void (^block)(void) = ^{
    if (target && selector) {
      [target performSelector:selector withObject:navController];
    }
  };
  logViewController.callbackBlock = block;

  navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;

  [navController pushViewController:logViewController animated:NO];
  return navController;
}

- (void)doneButtonClicked:(UIBarButtonItem *)barButtonItem {
  void (^block)() = self.callbackBlock;
  block();
  self.callbackBlock = nil;
}

@end

#pragma mark - Minimal WebView Controller

@implementation GTMHTTPFetcherLoggingWebViewController {
  NSURL *htmlURL_;
}

- (instancetype)initWithURL:(NSURL *)htmlURL
                      title:(NSString *)title {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.title = title;
    htmlURL_ = [htmlURL retain];
  }
  return self;
}

- (void)dealloc {
  [htmlURL_ release];
  [super dealloc];
}

- (void)loadView {
  UIWebView *webView = [[UIWebView alloc] init];
  webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                              | UIViewAutoresizingFlexibleHeight);
  webView.delegate = self;
  self.view = webView;
}

- (void)viewDidLoad {
  NSURLRequest *request = [NSURLRequest requestWithURL:htmlURL_];
  [[self webView] loadRequest:request];
}

- (void)didTapBackButton:(UIButton *)button {
  [[self webView] goBack];
}

- (UIWebView *)webView {
  return (UIWebView *)self.view;
}

#pragma mark - WebView delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  // Instead of the nav controller's back button, provide a simple
  // webview back button when it's needed.
  BOOL canGoBack = [webView canGoBack];
  UIBarButtonItem *backItem = nil;
  if (canGoBack) {
    // This hides the nav back button.
    backItem = [[[UIBarButtonItem alloc] initWithTitle:@"⏎"
                                                 style:UIBarButtonItemStylePlain
                                                target:self
                                                action:@selector(didTapBackButton:)] autorelease];
  }
  self.navigationItem.leftBarButtonItem = backItem;
}

@end

#endif  // !STRIP_GTM_FETCH_LOGGING && !STRIP_GTM_HTTPLOGVIEWCONTROLLER
