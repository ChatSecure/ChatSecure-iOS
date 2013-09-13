/* Copyright (c) 2009 Google Inc.
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

#import <SenTestingKit/SenTestingKit.h>

#import "GTMHTTPFetcherTestServer.h"
#import "GTMHTTPFetcher.h"
#import "GTMHTTPFetchHistory.h"
#import "GTMHTTPFetcherLogging.h"
#import "GTMHTTPUploadFetcher.h"

@interface GTMHTTPFetcherFetchingTest : SenTestCase {

  // these ivars are checked after fetches, and are reset by resetFetchResponse
  NSData *fetchedData_;
  NSError *fetcherError_;
  int fetchedStatus_;
  NSURLResponse *fetchedResponse_;
  NSMutableURLRequest *fetchedRequest_;
  int retryCounter_;

  int fetchStartedNotificationCount_;
  int fetchStoppedNotificationCount_;
  int retryDelayStartedNotificationCount_;
  int retryDelayStoppedNotificationCount_;

  // setup/teardown ivars
  GTMHTTPFetchHistory *fetchHistory_;
  GTMHTTPFetcherTestServer *testServer_;
  BOOL isServerRunning_;
}

- (void)testFetcher:(GTMHTTPFetcher *)fetcher
   finishedWithData:(NSData *)data
              error:(NSError *)error;

- (GTMHTTPFetcher *)doFetchWithURLString:(NSString *)urlString
                          cachingDatedData:(BOOL)doCaching;

- (GTMHTTPFetcher *)doFetchWithURLString:(NSString *)urlString
                          cachingDatedData:(BOOL)doCaching
                             retrySelector:(SEL)retrySel
                          maxRetryInterval:(NSTimeInterval)maxRetryInterval
                                credential:(NSURLCredential *)credential
                                  userData:(id)userData;

- (NSString *)localURLStringToTestFileName:(NSString *)name;
- (NSString *)localPathForFileName:(NSString *)name;
@end

// Authorization testing
@interface TestAuthorizer : NSObject <GTMFetcherAuthorizationProtocol> {
  BOOL hasExpired_;
}
@property (assign) BOOL expired;

+ (TestAuthorizer *)authorizer;
+ (TestAuthorizer *)expiredAuthorizer;
@end

static NSString *const kGoodBearerValue = @"Bearer good";
static NSString *const kExpiredBearerValue = @"Bearer expired";

@implementation GTMHTTPFetcherFetchingTest

static const NSTimeInterval kRunLoopInterval = 0.01;

//  The wrong-fetch test can take >10s to pass.
static const NSTimeInterval kGiveUpInterval = 30.0;

// file available in Tests folder
static NSString *const kValidFileName = @"gettysburgaddress.txt";

- (NSString *)docRootPath {
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  STAssertNotNil(testBundle, nil);

  NSString *docFolder = [testBundle resourcePath];
  return docFolder;
}

- (void)setUp {
  fetchHistory_ = [[GTMHTTPFetchHistory alloc] init];

  NSString *docRoot = [self docRootPath];

  testServer_ = [[GTMHTTPFetcherTestServer alloc] initWithDocRoot:docRoot];
  isServerRunning_ = (testServer_ != nil);

  STAssertTrue(isServerRunning_,
               @">>> http test server failed to launch; skipping"
               " fetcher tests\n");

  // install observers for fetcher notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(fetchStateChanged:) name:kGTMHTTPFetcherStartedNotification object:nil];
  [nc addObserver:self selector:@selector(fetchStateChanged:) name:kGTMHTTPFetcherStoppedNotification object:nil];
  [nc addObserver:self selector:@selector(retryDelayStateChanged:) name:kGTMHTTPFetcherRetryDelayStartedNotification object:nil];
  [nc addObserver:self selector:@selector(retryDelayStateChanged:) name:kGTMHTTPFetcherRetryDelayStoppedNotification object:nil];
}

- (void)resetFetchResponse {
  [fetchedData_ release];
  fetchedData_ = nil;

  [fetcherError_ release];
  fetcherError_ = nil;

  [fetchedRequest_ release];
  fetchedRequest_ = nil;

  [fetchedResponse_ release];
  fetchedResponse_ = nil;

  fetchedStatus_ = 0;

  retryCounter_ = 0;
}

- (void)tearDown {
  [testServer_ release];
  testServer_ = nil;

  isServerRunning_ = NO;

  [self resetFetchResponse];

  [fetchHistory_ release];
  fetchHistory_ = nil;
}

- (NSData *)gettysburgAddress {
  NSString *gettysburgPath = [testServer_ localPathForFile:kValidFileName];
  NSData *gettysburgAddress = [NSData dataWithContentsOfFile:gettysburgPath];
  return gettysburgAddress;
}

#pragma mark Notification callbacks

- (void)fetchStateChanged:(NSNotification *)note {
  if ([[note name] isEqual:kGTMHTTPFetcherStartedNotification]) {
    ++fetchStartedNotificationCount_;
  } else {
    ++fetchStoppedNotificationCount_;
  }

  STAssertTrue(fetchStoppedNotificationCount_ <= fetchStartedNotificationCount_,
               @"fetch notification imbalance: starts=%d stops=%d",
               fetchStartedNotificationCount_,
               fetchStoppedNotificationCount_);
}

- (void)retryDelayStateChanged:(NSNotification *)note {
  if ([[note name] isEqual:kGTMHTTPFetcherRetryDelayStartedNotification]) {
    ++retryDelayStartedNotificationCount_;
  } else {
    ++retryDelayStoppedNotificationCount_;
  }

  STAssertTrue(retryDelayStoppedNotificationCount_ <= retryDelayStartedNotificationCount_,
               @"retry delay notification imbalance: starts=%d stops=%d",
               retryDelayStartedNotificationCount_,
               retryDelayStoppedNotificationCount_);
}

- (void)resetNotificationCounts {
  fetchStartedNotificationCount_ = 0;
  fetchStoppedNotificationCount_ = 0;
  retryDelayStartedNotificationCount_ = 0;
  retryDelayStoppedNotificationCount_ = 0;
}

#pragma mark Tests

- (void)testFetch {
  if (!isServerRunning_) return;

  [self resetNotificationCounts];
  [self resetFetchResponse];

  NSString *urlString = [self localURLStringToTestFileName:kValidFileName];
  [self doFetchWithURLString:urlString cachingDatedData:YES];

  STAssertNotNil(fetchedData_,
                 @"failed to fetch data, status:%d error:%@, URL:%@",
                 fetchedStatus_, fetcherError_, urlString);

  // we'll verify we fetched from the server the actual data on disk
  NSData *gettysburgAddress = [self gettysburgAddress];
  STAssertEqualObjects(fetchedData_, gettysburgAddress,
                       @"Lincoln disappointed");

  STAssertNotNil(fetchedResponse_,
                 @"failed to get fetch response, status:%d error:%@",
                 fetchedStatus_, fetcherError_);
  STAssertNotNil(fetchedRequest_,
                 @"failed to get fetch request, URL %@", urlString);
  STAssertNil(fetcherError_, @"fetching data gave error: %@", fetcherError_);
  STAssertEquals(fetchedStatus_, 200,
                 @"unexpected status for URL %@", urlString);

  // no cookies should be sent with our first request
  NSDictionary *headers = [fetchedRequest_ allHTTPHeaderFields];
  NSString *cookiesSent = [headers objectForKey:@"Cookie"];
  STAssertNil(cookiesSent, @"Cookies sent unexpectedly: %@", cookiesSent);

  // cookies should have been set by the response; specifically, TestCookie
  // should be set to the name of the file requested
  NSDictionary *responseHeaders;

  responseHeaders = [(NSHTTPURLResponse *)fetchedResponse_ allHeaderFields];
  NSString *cookiesSetString = [responseHeaders objectForKey:@"Set-Cookie"];
  NSString *cookieExpected = [NSString stringWithFormat:@"TestCookie=%@",
    kValidFileName];
  STAssertEqualObjects(cookiesSetString, cookieExpected, @"Unexpected cookie");

  // make a copy of the fetched data to compare with our next fetch from the
  // cache
  NSData *originalFetchedData = [[fetchedData_ copy] autorelease];


  // Now fetch again so the "If-None-Match" header will be set (because
  // we're calling setFetchHistory: below) and caching ON, and verify that we
  // got a good data from the cache and a nil error, along with a
  // "Not Modified" status in the fetcher

  [self resetFetchResponse];

  [self doFetchWithURLString:urlString cachingDatedData:YES];

  STAssertEqualObjects(fetchedData_, originalFetchedData,
                       @"cache data mismatch");

  STAssertNotNil(fetchedData_,
                 @"failed to fetch data, status:%d error:%@, URL:%@",
                 fetchedStatus_, fetcherError_, urlString);
  STAssertNotNil(fetchedResponse_,
                 @"failed to get fetch response, status:%d error:%@",
                 fetchedStatus_, fetcherError_);
  STAssertNotNil(fetchedRequest_,
                 @"failed to get fetch request, URL %@",
                 urlString);
  STAssertNil(fetcherError_, @"fetching data gave error: %@", fetcherError_);

  STAssertEquals(fetchedStatus_, kGTMHTTPFetcherStatusNotModified, // 304
               @"fetch status unexpected for URL %@", urlString);

  // the TestCookie set previously should be sent with this request
  cookiesSent = [[fetchedRequest_ allHTTPHeaderFields] objectForKey:@"Cookie"];
  STAssertEqualObjects(cookiesSent, cookieExpected, @"Cookie not sent");


  // Now fetch twice without caching enabled, and verify that we got a
  // "Precondition failed" status, along with a non-nil but empty NSData (which
  // is normal for that status code) from the second fetch

  [self resetFetchResponse];

  [fetchHistory_ clearHistory];

  [self doFetchWithURLString:urlString cachingDatedData:NO];

  STAssertEqualObjects(fetchedData_, originalFetchedData,
                       @"cache data mismatch");
  STAssertNil(fetcherError_, @"unexpected error: %@", fetcherError_);

  [self resetFetchResponse];
  [self doFetchWithURLString:urlString cachingDatedData:NO];

  STAssertNotNil(fetchedData_, @"");
  STAssertEquals([fetchedData_ length], (NSUInteger) 0, @"unexpected data");
  STAssertEquals(fetchedStatus_, kGTMHTTPFetcherStatusNotModified,
         @"fetching data expected status 304, instead got %d", fetchedStatus_);
  STAssertNotNil(fetcherError_, @"missing 304 error");

  // check the notifications
  STAssertEquals(fetchStartedNotificationCount_, 4, @"fetches started");
  STAssertEquals(fetchStoppedNotificationCount_, 4, @"fetches stopped");
  STAssertEquals(retryDelayStartedNotificationCount_, 0, @"retries started");
  STAssertEquals(retryDelayStoppedNotificationCount_, 0, @"retries started");
}

- (void)testAuthorizorFetch {
  if (!isServerRunning_) return;
  [self resetNotificationCounts];

  //
  // fetch a live, authorized URL
  //
  NSString *authName = [kValidFileName stringByAppendingFormat:@"?oauth2=good"];
  NSString *authedURL = [self localURLStringToTestFileName:authName];

  NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:authedURL]
                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                   timeoutInterval:kGiveUpInterval];

  __block BOOL hasFinishedFetching = NO;
  __block GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
  STAssertNotNil(fetcher, @"Failed to allocate fetcher");

  fetcher.authorizer = [TestAuthorizer authorizer];

  void (^completionBlock)(NSData *, NSError *) = ^(NSData *data, NSError *error) {
    STAssertEqualObjects(data, [self gettysburgAddress], @"wrong data");
    STAssertNil(error, @"unexpected status error");
    hasFinishedFetching = YES;
  };

  [fetcher beginFetchWithCompletionHandler:completionBlock];
  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];
  STAssertTrue(hasFinishedFetching, @"auth 1 fetch failed");

  //
  // fetch with an expired authorizer, no retry allowed
  //
  authName = [kValidFileName stringByAppendingFormat:@"?oauth2=good"];
  authedURL = [self localURLStringToTestFileName:authName];

  req = [NSURLRequest requestWithURL:[NSURL URLWithString:authedURL]
                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                   timeoutInterval:kGiveUpInterval];

  hasFinishedFetching = NO;
  fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
  fetcher.retryBlock = ^(BOOL suggestedWillRetry, NSError *error) {
    return NO;
  };
  STAssertNotNil(fetcher, @"Failed to allocate fetcher");

  fetcher.authorizer = [TestAuthorizer expiredAuthorizer];

  completionBlock = ^(NSData *data, NSError *error) {
    STAssertEquals([error code], (NSInteger) 401,
                   @"unexpected status, error=%@", error);
    hasFinishedFetching = YES;
  };

  [fetcher beginFetchWithCompletionHandler:completionBlock];
  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];
  STAssertTrue(hasFinishedFetching, @"auth 2 fetch failed");

  //
  // fetch with an expired authorizer, with automatic refresh
  //
  authName = [kValidFileName stringByAppendingFormat:@"?oauth2=good"];
  authedURL = [self localURLStringToTestFileName:authName];

  req = [NSURLRequest requestWithURL:[NSURL URLWithString:authedURL]
                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                     timeoutInterval:kGiveUpInterval];

  hasFinishedFetching = NO;
  fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
  STAssertNotNil(fetcher, @"Failed to allocate fetcher");

  fetcher.authorizer = [TestAuthorizer expiredAuthorizer];

  completionBlock = ^(NSData *data, NSError *error) {
    STAssertEqualObjects(data, [self gettysburgAddress], @"wrong data");
    STAssertNil(error, @"unexpected error");
    hasFinishedFetching = YES;
  };

  [fetcher beginFetchWithCompletionHandler:completionBlock];
  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];
  STAssertTrue(hasFinishedFetching, @"auth 3 fetch failed");
}

- (void)testWrongFetch {

  if (!isServerRunning_) return;
  [self resetNotificationCounts];

  // fetch a live, invalid URL
  NSString *badURLString = @"http://localhost:86/";
  [self doFetchWithURLString:badURLString cachingDatedData:NO];

  if (fetchedData_) {
    NSString *str = [[[NSString alloc] initWithData:fetchedData_
                                           encoding:NSUTF8StringEncoding] autorelease];
    STAssertNil(fetchedData_, @"fetched unexpected data: %@", str);
  }

  STAssertNotNil(fetcherError_, @"failed to receive fetching error");
  STAssertEquals(fetchedStatus_, 0,
                 @"unexpected status from no response");

  // fetch with a specific status code from our http server
  [self resetFetchResponse];

  NSString *invalidWebPageFile = [kValidFileName stringByAppendingString:@"?status=400"];
  NSString *statusUrlString = [self localURLStringToTestFileName:invalidWebPageFile];

  [self doFetchWithURLString:statusUrlString cachingDatedData:NO];

  STAssertNotNil(fetchedData_, @"fetch lacked data with error info");
  STAssertNotNil(fetcherError_, @"expected status error");
  NSData *statusData = [[fetcherError_ userInfo] objectForKey:kGTMHTTPFetcherStatusDataKey];
  NSString *dataStr = [[[NSString alloc] initWithData:statusData
                                             encoding:NSUTF8StringEncoding] autorelease];
  NSString *expectedStr = @"{ \"error\" : { \"message\" : \"Server Status 400\", \"code\" : 400 } }";
  STAssertEqualObjects(dataStr, expectedStr, @"expected status data");
  
  STAssertEquals(fetchedStatus_, 400,
                 @"unexpected status, error=%@", fetcherError_);

  // check the notifications
  STAssertEquals(fetchStartedNotificationCount_, 2, @"fetches started");
  STAssertEquals(fetchStoppedNotificationCount_, 2, @"fetches stopped");
  STAssertEquals(retryDelayStartedNotificationCount_, 0, @"retries started");
  STAssertEquals(retryDelayStoppedNotificationCount_, 0, @"retries started");
}

- (void)testFetchToFile {
  if (!isServerRunning_) return;

  // create an empty file from which we can make an NSFileHandle
  NSString *path = [NSTemporaryDirectory() stringByAppendingFormat:@"fhTest_%@",
                    [NSDate date]];
  [[NSData data] writeToFile:path atomically:YES];

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
  STAssertNotNil(fileHandle, @"missing filehandle for %@", path);

  // make the http request to our test server
  __block NSString *testName = @"Download to file handle";

  NSString *urlString = [self localURLStringToTestFileName:kValidFileName];
  NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                   timeoutInterval:kGiveUpInterval];

  // we'll put fetcher in a __block variable so we can refer to the
  // latest instance of it in the callbacks
  __block GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
  STAssertNotNil(fetcher, @"Failed to allocate fetcher");

  // received-data block
  //
  // the final received-data block invocation should show the length of the
  // file actually downloaded
  __block NSUInteger receivedDataLen = 0;

  void (^receivedBlock)(NSData *) = ^(NSData *dataReceivedSoFar){
    // a nil data argument is expected when the downloaded data is written
    // to a file handle
    STAssertNil(dataReceivedSoFar, @"%@: unexpected dataReceivedSoFar",
                testName);

    receivedDataLen = [fetcher downloadedLength];
  };


  // fetch & completion block
  __block BOOL hasFinishedFetching = NO;

  void (^completionBlock)(NSData *, NSError *) = ^(NSData *data, NSError *error) {
    STAssertNil(data, @"%@: unexpected data", testName);
    STAssertNil(error, @"%@: unexpected error: %@", testName, error);

    NSString *fetchedContents = [NSString stringWithContentsOfFile:path
                                                          encoding:NSUTF8StringEncoding
                                                             error:NULL];
    STAssertEquals(receivedDataLen, [fetchedContents length],
                   @"%@: length issue", testName);

    NSString *origPath = [self localPathForFileName:kValidFileName];
    NSString *origContents = [NSString stringWithContentsOfFile:origPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL];
    STAssertEqualObjects(fetchedContents, origContents,
                         @"%@: fetch to FH error", testName);

    hasFinishedFetching = YES;
  };

  [fetcher setDownloadFileHandle:fileHandle];
  [fetcher setReceivedDataBlock:receivedBlock];
  [fetcher beginFetchWithCompletionHandler:completionBlock];

  // spin until the fetch completes
  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];
  STAssertTrue(hasFinishedFetching, @"file handle fetch timed out");

  [[NSFileManager defaultManager] removeItemAtPath:path
                                             error:NULL];

  //
  // repeat the test with a new fetcher, writing directly to the path
  // instead of explicitly creating a file handle
  //
  hasFinishedFetching = NO;

  testName = @"Download to file path";
  fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
  [fetcher setDownloadPath:path];
  [fetcher setReceivedDataBlock:receivedBlock];
  [fetcher beginFetchWithCompletionHandler:completionBlock];

  // grab a copy of the temporary file path
  NSString *tempPath = [[[fetcher performSelector:@selector(temporaryDownloadPath)] copy] autorelease];

  // spin until the fetch completes
  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];
  STAssertTrue(hasFinishedFetching, @"path fetch timed out");

  // verify that the temp file has been deleted
  BOOL doesExist = [[NSFileManager defaultManager] fileExistsAtPath:tempPath];
  STAssertFalse(doesExist, @"%@: temp file should not exist", testName);

  [[NSFileManager defaultManager] removeItemAtPath:path
                                             error:NULL];
  
  //
  // repeat the test with a new fetcher, writing directly to a path,
  // but with a fetch that will fail
  //
  hasFinishedFetching = NO;

  testName = @"Invalid download to file path";
  NSString *invalidFile = [kValidFileName stringByAppendingString:@"?status=400"];
  urlString = [self localURLStringToTestFileName:invalidFile];
  req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                     timeoutInterval:kGiveUpInterval];
  fetcher = [GTMHTTPFetcher fetcherWithRequest:req];
  [fetcher setDownloadPath:path];
  [fetcher setReceivedDataBlock:receivedBlock];

  [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
    STAssertNil(data, @"%@: unexpected data", testName);
    STAssertEquals([error code], (NSInteger) 400,
                   @"%@: unexpected error: %@", testName, error);
    hasFinishedFetching = YES;
  }];

  // grab a copy of the temporary file path
  tempPath = [[[fetcher performSelector:@selector(temporaryDownloadPath)] copy] autorelease];
  
  // spin until the fetch completes
  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];
  STAssertTrue(hasFinishedFetching, @"path fetch timed out");

  // the file at the temporary path should be gone, and none should be at
  // the final path
  //
  // we test it here rather than in the callback since it's not deleted
  // until the fetcher does its stopFetching cleanup
  doesExist = [[NSFileManager defaultManager] fileExistsAtPath:tempPath];
  STAssertFalse(doesExist, @"%@: temp file should not exist", testName);

  doesExist = [[NSFileManager defaultManager] fileExistsAtPath:path];
  STAssertFalse(doesExist, @"%@: file should not exist", testName);
}

- (void)testRetryFetches {

  if (!isServerRunning_) return;
  [self resetNotificationCounts];

  GTMHTTPFetcher *fetcher;

  NSString *invalidFile = [kValidFileName stringByAppendingString:@"?status=503"];
  NSString *urlString = [self localURLStringToTestFileName:invalidFile];

  SEL countRetriesSel = @selector(countRetriesfetcher:willRetry:forError:);
  SEL fixRequestSel = @selector(fixRequestFetcher:willRetry:forError:);

  //
  // test: retry until timeout, then expect failure with status message
  //

  NSNumber *lotsOfRetriesNumber = [NSNumber numberWithInt:1000];

  fetcher= [self doFetchWithURLString:urlString
                     cachingDatedData:NO
                        retrySelector:countRetriesSel
                     maxRetryInterval:5.0 // retry intervals of 1, 2, 4
                           credential:nil
                             userData:lotsOfRetriesNumber];

  STAssertNotNil(fetchedData_, @"error data is expected");
  STAssertEquals(fetchedStatus_, 503,
                 @"fetchedStatus_ should be 503, was %@", fetchedStatus_);
  STAssertEquals([fetcher retryCount], (NSUInteger) 3, @"retry count unexpected");

  //
  // test:  retry twice, then give up
  //
  [self resetFetchResponse];

  NSNumber *twoRetriesNumber = [NSNumber numberWithInt:2];

  fetcher= [self doFetchWithURLString:urlString
                     cachingDatedData:NO
                        retrySelector:countRetriesSel
                     maxRetryInterval:10.0 // retry intervals of 1, 2, 4, 8
                           credential:nil
                             userData:twoRetriesNumber];

  STAssertNotNil(fetchedData_, @"error data is expected");
  STAssertEquals(fetchedStatus_, 503,
                 @"fetchedStatus_ should be 503, was %@", fetchedStatus_);
  STAssertEquals([fetcher retryCount], (NSUInteger) 2, @"retry count unexpected");


  //
  // test:  retry, making the request succeed on the first retry
  //        by fixing the URL
  //
  [self resetFetchResponse];

  fetcher= [self doFetchWithURLString:urlString
                     cachingDatedData:NO
                        retrySelector:fixRequestSel
                     maxRetryInterval:30.0 // should only retry once due to selector
                           credential:nil
                             userData:lotsOfRetriesNumber];

  STAssertNotNil(fetchedData_, @"data is expected");
  STAssertEquals(fetchedStatus_, 200,
                 @"fetchedStatus_ should be 200, was %@", fetchedStatus_);
  STAssertEquals([fetcher retryCount], (NSUInteger) 1, @"retry count unexpected");

  // check the notifications
  STAssertEquals(fetchStartedNotificationCount_, 9, @"fetches started");
  STAssertEquals(fetchStoppedNotificationCount_, 9, @"fetches stopped");
  STAssertEquals(retryDelayStartedNotificationCount_, 6, @"retries started");
  STAssertEquals(retryDelayStoppedNotificationCount_, 6, @"retries started");
}

#pragma mark Upload fetches

- (NSData *)generatedUploadDataWithLength:(NSUInteger)length {
  // fill a data block with data
  NSMutableData *data = [NSMutableData dataWithLength:length];

  unsigned char *bytes = [data mutableBytes];
  for (NSUInteger idx = 0; idx < length; idx++) {
    bytes[idx] = ((idx + 1) % 256);
  }

  return data;
}

static NSString* const kPauseAtKey = @"pauseAt";
static NSString* const kRetryAtKey = @"retryAt";
static NSString* const kOriginalURLKey = @"origURL";

- (void)uploadFetcher:(GTMHTTPUploadFetcher *)fetcher
         didSendBytes:(NSInteger)bytesSent
       totalBytesSent:(NSInteger)totalBytesSent
totalBytesExpectedToSend:(NSInteger)totalBytesExpectedToSend {

  NSNumber *pauseAtNum = [fetcher propertyForKey:kPauseAtKey];
  if (pauseAtNum) {
    int pauseAt = [pauseAtNum intValue];
    if (pauseAt < totalBytesSent) {
      // we won't be paused again
      [fetcher setProperty:nil forKey:kPauseAtKey];

      // we've reached the point where we should pause
      //
      // use perform selector to avoid pausing immediately, as that would nuke
      // the chunk upload fetcher that is calling us back now
      [fetcher performSelector:@selector(pauseFetching)
                    withObject:nil
                    afterDelay:0.0];
      
      [fetcher performSelector:@selector(resumeFetching)
                    withObject:nil
                    afterDelay:1.0];
    }
  }

  NSNumber *retryAtNum = [fetcher propertyForKey:kRetryAtKey];
  if (retryAtNum) {
    int retryAt = [retryAtNum intValue];
    if (retryAt < totalBytesSent) {
      // we won't be retrying again
      [fetcher setProperty:nil forKey:kRetryAtKey];

      // save the current locationURL before appending &status=503
      NSURL *origURL = fetcher.locationURL;
      [fetcher setProperty:origURL forKey:kOriginalURLKey];

      NSString *newURLStr = [[origURL absoluteString] stringByAppendingString:@"?status=503"];
      fetcher.locationURL = [NSURL URLWithString:newURLStr];
    }
  }
}


-(BOOL)uploadRetryFetcher:(GTMHTTPUploadFetcher *)fetcher willRetry:(BOOL)suggestedWillRetry forError:(NSError *)error {
  // change this fetch's request (and future requests) to have the original URL,
  // not the one with status=503 appended
  NSURL *origURL = [fetcher propertyForKey:kOriginalURLKey];

  [fetcher.activeFetcher.mutableRequest setURL:origURL];
  fetcher.locationURL = origURL;

  [fetcher setProperty:nil forKey:kOriginalURLKey];

  return suggestedWillRetry; // do the retry fetch; it should succeed now
}

- (void)testChunkedUploadFetch {
  if (!isServerRunning_) return;

  NSData *bigData = [self generatedUploadDataWithLength:199000];
  NSData *smallData = [self generatedUploadDataWithLength:13];

  NSData *gettysburgAddress = [self gettysburgAddress];

  // write the big data into a temp file
  NSString *tempDir = NSTemporaryDirectory();
  NSString *bigFileName = @"GTMFetchingTest_BigFile";
  NSString *bigFilePath = [tempDir stringByAppendingPathComponent:bigFileName];
  [bigData writeToFile:bigFilePath atomically:NO];

  NSFileHandle *bigFileHandle = [NSFileHandle fileHandleForReadingAtPath:bigFilePath];

  SEL progressSel = @selector(uploadFetcher:didSendBytes:totalBytesSent:totalBytesExpectedToSend:);
  SEL retrySel = @selector(uploadRetryFetcher:willRetry:forError:);
  SEL finishedSel = @selector(testFetcher:finishedWithData:error:);

  NSString *urlString = [self localURLStringToTestFileName:kValidFileName];
  urlString = [urlString stringByAppendingPathExtension:@"location"];

  [self resetNotificationCounts];

  //
  // test uploading a big file handle
  //
  [self resetFetchResponse];

  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                       timeoutInterval:kGiveUpInterval];

  GTMHTTPUploadFetcher *fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                                uploadFileHandle:bigFileHandle
                                                                  uploadMIMEType:@"text/plain"
                                                                       chunkSize:75000
                                                                  fetcherService:nil];

  [fetcher beginFetchWithDelegate:self
                didFinishSelector:finishedSel];

  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];


  STAssertNotNil(fetchedData_,
                 @"failed to fetch data, status:%d error:%@, URL:%@",
                 fetchedStatus_, fetcherError_, urlString);

  // check that we fetched the expected data
  STAssertEqualObjects(fetchedData_, gettysburgAddress,
                       @"Lincoln disappointed");
  STAssertNotNil(fetchedResponse_,
                 @"failed to get fetch response, status:%d error:%@",
                 fetchedStatus_, fetcherError_);
  STAssertNotNil(fetchedRequest_,
                 @"failed to get fetch request, URL %@", urlString);
  STAssertNil(fetcherError_, @"fetching data gave error: %@", fetcherError_);
  STAssertEquals(fetchedStatus_, 200,
                 @"unexpected status for URL %@", urlString);

  // check the request of the final chunk fetcher to be sure we were uploading
  // chunks as expected.  Chunk requests replace the original request in the
  // fetcher.
  NSDictionary *reqHdrs = [fetcher.mutableRequest allHTTPHeaderFields];

  NSString *uploadReqURLPath = @"gettysburgaddress.txt.location";
  NSString *contentLength = [reqHdrs objectForKey:@"Content-Length"];
  NSString *contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertTrue([[[request URL] absoluteString] hasSuffix:uploadReqURLPath],
               @"upload request wrong");
  STAssertEqualObjects(contentLength, @"49000", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 150000-198999/199000", @"range");

  //
  // repeat the big upload using NSData
  //
  [self resetFetchResponse];

  request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                         timeoutInterval:kGiveUpInterval];

  fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                uploadData:bigData
                                            uploadMIMEType:@"text/plain"
                                                 chunkSize:75000
                                            fetcherService:nil];

  [fetcher beginFetchWithDelegate:self
                didFinishSelector:finishedSel];

  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];

  // check that we fetched the expected data
  STAssertEqualObjects(fetchedData_, gettysburgAddress,
                       @"Lincoln disappointed");
  STAssertNotNil(fetchedResponse_,
                 @"failed to get fetch response, status:%d error:%@",
                 fetchedStatus_, fetcherError_);
  STAssertNotNil(fetchedRequest_,
                 @"failed to get fetch request, URL %@", urlString);
  STAssertNil(fetcherError_, @"fetching data gave error: %@", fetcherError_);
  STAssertEquals(fetchedStatus_, 200,
                 @"unexpected status for URL %@", urlString);

  // check the request of the final chunk fetcher
  reqHdrs = [fetcher.mutableRequest allHTTPHeaderFields];

  uploadReqURLPath = @"gettysburgaddress.txt.location";
  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertTrue([[[request URL] absoluteString] hasSuffix:uploadReqURLPath],
               @"upload request wrong");
  STAssertEqualObjects(contentLength, @"49000", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 150000-198999/199000", @"range");


  //
  // repeat the big upload, pausing after 20000 bytes
  //
  [self resetFetchResponse];

  fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                uploadData:bigData
                                            uploadMIMEType:@"text/plain"
                                                 chunkSize:75000
                                            fetcherService:nil];

  // add a property to the fetcher that our progress callback will look for to
  // know when to pause and resume the upload
  fetcher.sentDataSelector = progressSel;
  [fetcher setProperty:[NSNumber numberWithInt:20000]
                forKey:kPauseAtKey];

  [fetcher beginFetchWithDelegate:self
                didFinishSelector:finishedSel];

  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];

  // check the request of the final chunk fetcher to be sure we were uploading
  // chunks as expected.
  reqHdrs = [fetcher.mutableRequest allHTTPHeaderFields];

  uploadReqURLPath = @"gettysburgaddress.txt.location";
  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertTrue([[[request URL] absoluteString] hasSuffix:uploadReqURLPath],
               @"upload request wrong");
  STAssertEqualObjects(contentLength, @"24499", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 174501-198999/199000", @"range");

  
  //
  // repeat the big upload using blocks instead of a delegate,
  // pausing after 20000 bytes
  //
  // for the blocks test, the body of the blocks will just invoke the non-block
  // callback methods
  //
  [self resetFetchResponse];

  fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                uploadData:bigData
                                            uploadMIMEType:@"text/plain"
                                                 chunkSize:75000
                                            fetcherService:nil];

  [fetcher setSentDataBlock:^(NSInteger bytesSent, NSInteger totalBytesSent, NSInteger expectedBytes) {
    [self uploadFetcher:fetcher
           didSendBytes:bytesSent
         totalBytesSent:totalBytesSent
totalBytesExpectedToSend:expectedBytes];
  }];

  [fetcher setProperty:[NSNumber numberWithInt:20000]
                forKey:kPauseAtKey];

  [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
    [self testFetcher:fetcher
     finishedWithData:data
                error:error];
  }];

  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];

  // check the request of the final chunk fetcher to be sure we were uploading
  // chunks as expected.
  reqHdrs = [fetcher.mutableRequest allHTTPHeaderFields];

  uploadReqURLPath = @"gettysburgaddress.txt.location";
  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertTrue([[[request URL] absoluteString] hasSuffix:uploadReqURLPath],
               @"upload request wrong");
  STAssertEqualObjects(contentLength, @"24499", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 174501-198999/199000", @"range");


  //
  // repeat the upload, and after sending 70000 bytes the progress
  // callback will change the request URL for the next chunk fetch to make
  // it fail with a retryable status error
  //

  [self resetFetchResponse];

  fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                uploadData:bigData
                                            uploadMIMEType:@"text/plain"
                                                 chunkSize:75000
                                            fetcherService:nil];
  fetcher.retryEnabled = YES;
  fetcher.retrySelector = retrySel;
  fetcher.sentDataSelector = progressSel;

  // add a property to the fetcher that our progress callback will look for to
  // know when to retry the upload
  [fetcher setProperty:[NSNumber numberWithInt:70000]
                forKey:kRetryAtKey];

  [fetcher beginFetchWithDelegate:self
                didFinishSelector:finishedSel];

  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];

  // check the request of the final chunk fetcher to be sure we were uploading
  // chunks as expected.
  reqHdrs = [fetcher.mutableRequest allHTTPHeaderFields];

  uploadReqURLPath = @"gettysburgaddress.txt.location";
  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertTrue([[[request URL] absoluteString] hasSuffix:uploadReqURLPath],
               @"upload request wrong");
  STAssertEqualObjects(contentLength, @"24499", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 174501-198999/199000", @"range");


  //
  // repeat the forced-retry upload, using blocks
  //

  [self resetFetchResponse];
  fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                uploadData:bigData
                                            uploadMIMEType:@"text/plain"
                                                 chunkSize:75000
                                            fetcherService:nil];
  fetcher.retryEnabled = YES;
  [fetcher setRetryBlock:^(BOOL suggestedWillRetry, NSError *error) {
    BOOL shouldRetry = [self uploadRetryFetcher:fetcher
                                      willRetry:suggestedWillRetry
                                       forError:error];
    return shouldRetry;
  }];

  [fetcher setSentDataBlock:^(NSInteger bytesSent, NSInteger totalBytesSent, NSInteger expectedBytes) {
    [self uploadFetcher:fetcher
           didSendBytes:bytesSent
         totalBytesSent:totalBytesSent
totalBytesExpectedToSend:expectedBytes];
  }];

  // add a property to the fetcher that our progress callback will look for to
  // know when to retry the upload
  [fetcher setProperty:[NSNumber numberWithInt:70000]
                forKey:kRetryAtKey];

  [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
    [self testFetcher:fetcher
     finishedWithData:data
                error:error];
  }];
   
  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];

  // check the request of the final chunk fetcher to be sure we were uploading
  // chunks as expected.
  reqHdrs = [fetcher.mutableRequest allHTTPHeaderFields];

  uploadReqURLPath = @"gettysburgaddress.txt.location";
  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertTrue([[[request URL] absoluteString] hasSuffix:uploadReqURLPath],
               @"upload request wrong");
  STAssertEqualObjects(contentLength, @"24499", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 174501-198999/199000", @"range");


  //
  // upload a small buffer
  //
  [self resetFetchResponse];

  fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                uploadData:smallData
                                            uploadMIMEType:@"text/plain"
                                                 chunkSize:75000
                                            fetcherService:nil];

  [fetcher beginFetchWithDelegate:self
                didFinishSelector:finishedSel];

  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];

  // check that we fetched the expected data
  STAssertEqualObjects(fetchedData_, gettysburgAddress,
                       @"Lincoln disappointed");
  STAssertNotNil(fetchedResponse_,
                 @"failed to get fetch response, status:%d error:%@",
                 fetchedStatus_, fetcherError_);
  STAssertNotNil(fetchedRequest_,
                 @"failed to get fetch request, URL %@", urlString);
  STAssertNil(fetcherError_, @"fetching data gave error: %@", fetcherError_);
  STAssertEquals(fetchedStatus_, 200,
                 @"unexpected status for URL %@", urlString);

  // check the request of the final chunk fetcher to be sure we were uploading
  // chunks as expected
  reqHdrs = [fetcher.mutableRequest allHTTPHeaderFields];

  uploadReqURLPath = @"gettysburgaddress.txt.location";
  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertTrue([[[request URL] absoluteString] hasSuffix:uploadReqURLPath],
               @"upload request wrong");
  STAssertEqualObjects(contentLength, @"13", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 0-12/13", @"range");

  //
  // upload an empty buffer
  //
  [self resetFetchResponse];

  fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                uploadData:[NSData data]
                                            uploadMIMEType:@"text/plain"
                                                 chunkSize:75000
                                            fetcherService:nil];

  [fetcher beginFetchWithDelegate:self
                didFinishSelector:finishedSel];

  [fetcher waitForCompletionWithTimeout:kGiveUpInterval];

  // check that we fetched the expected data
  STAssertEqualObjects(fetchedData_, gettysburgAddress,
                       @"unexpected response data");
  STAssertNotNil(fetchedResponse_,
                 @"failed to get fetch response, status:%d error:%@",
                 fetchedStatus_, fetcherError_);
  STAssertNotNil(fetchedRequest_,
                 @"failed to get fetch request, URL %@", urlString);
  STAssertNil(fetcherError_, @"fetching data gave error: %@", fetcherError_);
  STAssertEquals(fetchedStatus_, 200,
                 @"unexpected status for URL %@", urlString);

  //
  // delete the big file
  //
  [[NSFileManager defaultManager] removeItemAtPath:bigFilePath
                                             error:NULL];
}

#pragma mark -

- (GTMHTTPFetcher *)doFetchWithURLString:(NSString *)urlString
                          cachingDatedData:(BOOL)doCaching {

  return [self doFetchWithURLString:(NSString *)urlString
                   cachingDatedData:doCaching
                      retrySelector:nil
                   maxRetryInterval:0
                         credential:nil
                           userData:nil];
}

- (GTMHTTPFetcher *)doFetchWithURLString:(NSString *)urlString
                        cachingDatedData:(BOOL)doCaching
                           retrySelector:(SEL)retrySel
                        maxRetryInterval:(NSTimeInterval)maxRetryInterval
                              credential:(NSURLCredential *)credential
                                userData:(id)userData {
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *req = [NSURLRequest requestWithURL:url
                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                   timeoutInterval:kGiveUpInterval];
  GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:req];

  STAssertNotNil(fetcher, @"Failed to allocate fetcher");

  // setting the fetch history will add the "If-modified-since" header
  // to repeat requests
  [fetchHistory_ setShouldCacheETaggedData:doCaching];
  [fetcher setFetchHistory:fetchHistory_];

  if (retrySel) {
    [fetcher setRetryEnabled:YES];
    [fetcher setRetrySelector:retrySel];
    [fetcher setMaxRetryInterval:maxRetryInterval];
    [fetcher setUserData:userData];

    // we force a minimum retry interval for unit testing; otherwise,
    // we'd have no idea how many retries will occur before the max
    // retry interval occurs, since the minimum would be random
    [fetcher setMinRetryInterval:1.0];
  }

  [fetcher setCredential:credential];

  BOOL isFetching = [fetcher beginFetchWithDelegate:self
                                  didFinishSelector:@selector(testFetcher:finishedWithData:error:)];
  STAssertTrue(isFetching, @"Begin fetch failed");

  if (isFetching) {
    [fetcher waitForCompletionWithTimeout:kGiveUpInterval];
  }
  return fetcher;
}

- (NSString *)localPathForFileName:(NSString *)name {
  NSString *docRoot = [self docRootPath];
  NSString *filePath = [docRoot stringByAppendingPathComponent:name];
  return filePath;
}

- (NSString *)localURLStringToTestFileName:(NSString *)name {

  // we need to create http URLs referring to the desired
  // resource to be found by the http server running locally

  // return a localhost:port URL for the test file
  NSString *urlString = [NSString stringWithFormat:@"http://localhost:%d/%@",
    [testServer_ port], name];

  // we exclude parameters
  NSRange range = [name rangeOfString:@"?"];
  if (range.location != NSNotFound) {
    name = [name substringToIndex:range.location];
  }

  // just for sanity, let's make sure we see the file locally, so
  // we can expect the Python http server to find it too
  NSString *filePath = [self localPathForFileName:name];

  BOOL doesExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
  STAssertTrue(doesExist, @"Missing test file %@", filePath);

  return urlString;
}

- (void)testFetcher:(GTMHTTPFetcher *)fetcher
   finishedWithData:(NSData *)data
              error:(NSError *)error {
  fetchedData_ = [data copy];
  fetchedStatus_ = [fetcher statusCode];
  fetchedRequest_ = [[fetcher mutableRequest] retain];
  fetchedResponse_ = [[fetcher response] retain];
  fetcherError_ = [error retain];
}


// Selector for allowing up to N retries, where N is an NSNumber in the
// fetcher's userData
- (BOOL)countRetriesfetcher:(GTMHTTPFetcher *)fetcher
                  willRetry:(BOOL)suggestedWillRetry
                   forError:(NSError *)error {

  int count = [fetcher retryCount];
  int allowedRetryCount = [[fetcher userData] intValue];

  BOOL shouldRetry = (count < allowedRetryCount);

  STAssertEquals([fetcher nextRetryInterval], pow(2.0, [fetcher retryCount]),
                 @"unexpected next retry interval (expected %f, was %f)",
                 pow(2.0, [fetcher retryCount]),
                 [fetcher nextRetryInterval]);

  NSData *statusData = [[error userInfo] objectForKey:kGTMHTTPFetcherStatusDataKey];
  NSString *dataStr = [[[NSString alloc] initWithData:statusData
                                             encoding:NSUTF8StringEncoding] autorelease];
  NSString *expectedStr = @"{ \"error\" : { \"message\" : \"Server Status 503\", \"code\" : 503 } }";
  STAssertEqualObjects(dataStr, expectedStr, nil);

  return shouldRetry;
}

// Selector for retrying and changing the request to one that will succeed
- (BOOL)fixRequestFetcher:(GTMHTTPFetcher *)fetcher
                willRetry:(BOOL)suggestedWillRetry
                 forError:(NSError *)error {

  STAssertEquals([fetcher nextRetryInterval], pow(2.0, [fetcher retryCount]),
                 @"unexpected next retry interval (expected %f, was %f)",
                 pow(2.0, [fetcher retryCount]),
                 [fetcher nextRetryInterval]);

  // fix it - change the request to a URL which does not have a status value
  NSString *urlString = [self localURLStringToTestFileName:kValidFileName];

  NSURL *url = [NSURL URLWithString:urlString];
  [[fetcher mutableRequest] setURL:url];

  return YES; // do the retry fetch; it should succeed now
}

@end

@implementation TestAuthorizer

@synthesize expired = hasExpired_;

+ (TestAuthorizer *)authorizer {
  return [[[self alloc] init] autorelease];
}

+ (TestAuthorizer *)expiredAuthorizer {
  TestAuthorizer *authorizer = [self authorizer];
  authorizer.expired = YES;
  return authorizer;
}

- (void)authorizeRequest:(NSMutableURLRequest *)request
                delegate:(id)delegate
       didFinishSelector:(SEL)sel {
  NSString *value = self.expired ? kExpiredBearerValue : kGoodBearerValue;
  [request setValue:value forHTTPHeaderField:@"Authorization"];
  NSError *error = nil;

  if (delegate && sel) {
    NSMethodSignature *sig = [delegate methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setSelector:sel];
    [invocation setTarget:delegate];
    [invocation setArgument:&self atIndex:2];
    [invocation setArgument:&request atIndex:3];
    [invocation setArgument:&error atIndex:4];
    [invocation invoke];
  }
}

- (void)stopAuthorization {
}

- (void)stopAuthorizationForRequest:(NSURLRequest *)request {
}

- (BOOL)isAuthorizingRequest:(NSURLRequest *)request {
  return NO;
}

- (BOOL)isAuthorizedRequest:(NSURLRequest *)request {
  NSString *value = [[request allHTTPHeaderFields] objectForKey:@"Authorization"];
  BOOL isValid = [value isEqual:kGoodBearerValue];
  return isValid;
}

- (NSString *)userEmail {
 return @"";
}

- (BOOL)primeForRefresh {
  self.expired = NO;
  return YES;
}

@end
