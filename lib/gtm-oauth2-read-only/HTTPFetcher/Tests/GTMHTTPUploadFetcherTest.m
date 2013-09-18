/* Copyright (c) 2010 Google Inc.
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

//
//  GTMHTTPUploadFetcherTest.m
//

#import <SenTestingKit/SenTestingKit.h>

#import "GTMHTTPUploadFetcher.h"
#import "GTMHTTPFetcherTestServer.h"

@interface GTMHTTPUploadFetcherTest : SenTestCase {
  GTMHTTPFetcherTestServer *testServer_;
  BOOL isServerRunning_;

  GTMHTTPFetchHistory *fetchHistory_;
  
  GTMHTTPFetcher *fetcher_;
  NSError *fetcherError_;
  unsigned long long lastProgressDeliveredCount_;
  unsigned long long lastProgressTotalCount_;
}
@end


@implementation GTMHTTPUploadFetcherTest

static NSString *const kValidFileName = @"gettysburgaddress.txt";

- (NSURL *)localURLForFileName:(NSString *)name {
  // return a localhost:port URL for the test file
  NSString *str = [NSString stringWithFormat:@"http://localhost:%d/%@",
                [testServer_ port], name];
  NSURL *url = [NSURL URLWithString:str];
  return url;
}

- (NSString *)docPathForName:(NSString *)fileName {
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  STAssertNotNil(testBundle, nil);
  
  NSString *docPath = [testBundle pathForResource:fileName
                                           ofType:nil];
  STAssertNotNil(docPath, nil);
  return docPath;
}

- (NSString *)docRootPath {
  NSString *docRoot = [self docPathForName:kValidFileName];
  docRoot = [docRoot stringByDeletingLastPathComponent];
  return docRoot;
}

- (void)setUp {
  fetchHistory_ = [[GTMHTTPFetchHistory alloc] init];
  
  NSString *docRoot = [self docRootPath];

  testServer_ = [[GTMHTTPFetcherTestServer alloc] initWithDocRoot:docRoot];
  isServerRunning_ = (testServer_ != nil);
  
  STAssertTrue(isServerRunning_,
               @">>> http test server failed to launch; skipping"
               " fetcher tests\n");
}

- (void)tearDown {
  [testServer_ release];
  testServer_ = nil;
  
  isServerRunning_ = NO;
}
/*
- (void)retryDelayStateChanged:(NSNotification *)note {
  GDataHTTPFetcher *fetcher = [note object];
  GDataServiceTicketBase *ticket = [fetcher ticket];

  STAssertNotNil(ticket, @"cannot get ticket from retry delay notification");

  if ([[note name] isEqual:kGDataHTTPFetcherRetryDelayStartedNotification]) {
    ++retryDelayStartedNotificationCount_;
  } else {
    ++retryDelayStoppedNotificationCount_;
  }

  STAssertTrue(retryDelayStoppedNotificationCount_ <= retryDelayStartedNotificationCount_,
               @"retry delay notification imbalance: starts=%d stops=%d",
               retryDelayStartedNotificationCount_,
               retryDelayStoppedNotificationCount_);
}
*/
/*
- (void)resetFetchResponse {
  
//  [fetchedObject_ release];
//  fetchedObject_ = nil;

  [fetcherError_ release];
  fetcherError_ = nil;

  [ticket_ release];
  ticket_ = nil;

  retryCounter_ = 0;

  lastProgressDeliveredCount_ = 0;
  lastProgressTotalCount_ = 0;

  // Set the UA to avoid log warnings during tests, except the first test,
  // which will use an auto-generated user agent
  if ([service_ userAgent] == nil) {
    [service_ setUserAgent:@"GData-UnitTests-99.99"];
  }

  if (![service_ shouldCacheDatedData]) {
    // we don't want to see 304s in our service response tests now,
    // though the tests below will check for them in the underlying
    // fetchers when we get a cached response
    [service_ clearLastModifiedDates];
  }

  fetchStartedNotificationCount_ = 0;
  fetchStoppedNotificationCount_ = 0;
  parseStartedCount_ = 0;
  parseStoppedCount_ = 0;
  retryDelayStartedNotificationCount_ = 0;
  retryDelayStoppedNotificationCount_ = 0;
}
*/

- (void)waitForFetch {

  int fetchCounter = gFetchCounter;

  // Give time for the fetch to happen, but give up if
  // 10 seconds elapse with no response
  NSDate* giveUpDate = [NSDate dateWithTimeIntervalSinceNow:10.0];

  while ((!fetchedObject_ && !fetcherError_)
         && [giveUpDate timeIntervalSinceNow] > 0) {

    NSDate *stopDate = [NSDate dateWithTimeIntervalSinceNow:0.001];
    [[NSRunLoop currentRunLoop] runUntilDate:stopDate];
  }

}


#pragma mark Upload tests

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

- (void)testChunkedUpload {

  if (!isServerRunning_) return;

  NSData *bigData = [self generatedUploadDataWithLength:199000];
  //NSData *smallData = [self generatedUploadDataWithLength:13];

  // write the big data into a temp file
  NSString *tempDir = NSTemporaryDirectory();
  NSString *bigFileName = @"GDataServiceTest_BigFile";
  NSString *bigFilePath = [tempDir stringByAppendingPathComponent:bigFileName];
  [bigData writeToFile:bigFilePath atomically:NO];

  NSFileHandle *bigFileHandle = [NSFileHandle fileHandleForReadingAtPath:bigFilePath];

  //
  // test a big upload using an NSFileHandle
  //

  // with chunk size 75000, for a data block of 199000 bytes, we expect to send
  // two 75000-byte chunks and then a 49000-byte final chunk


  // a ".location" tells the server to return a "Location" header with the
  // same path but an ".upload" suffix replacing the ".location" suffix
  static NSString *const kValidFileLocation = @"gettysburgaddress.txt.location";

  NSURL *docURL = [self localURLForFileName:kValidFileLocation];
  NSLog(@"docURL = %@", docURL);
  STAssertNotNil(docURL, nil);
  NSURLRequest *request = [NSURLRequest requestWithURL:docURL];
  NSLog(@"request = %@", request);
  GTMHTTPUploadFetcher *fetcher = [GTMHTTPUploadFetcher uploadFetcherWithRequest:request
                                                                uploadFileHandle:bigFileHandle
                                                                  uploadMIMEType:@"text/plain"
                                                                       chunkSize:75000];
  NSLog(@"fetcher %@", fetcher);
  BOOL isFetching = [fetcher beginFetchWithDelegate:self
                                  didFinishSelector:@selector(uploadFetcher:finishedWithData:error:)];
  [self waitForFetch];

  // set retry and progress
  
  // TODO...
  /*
  ticket_ = [service_ fetchEntryByInsertingEntry:newEntry
                                      forFeedURL:uploadURL
                                        delegate:self
                               didFinishSelector:@selector(ticket:finishedWithObject:error:)];
  [ticket_ retain];

  [self waitForFetch];

  STAssertNil(fetcherError_, @"fetcherError_=%@", fetcherError_);

  // check that we got back the expected entry
  NSString *entryID = @"http://spreadsheets.google.com/feeds/cells/o04181601172097104111.497668944883620000/od6/private/full/R1C1";
  STAssertEqualObjects([(GDataEntrySpreadsheetCell *)fetchedObject_ identifier],
                       entryID, @"uploading %@", uploadURL);

  // check the request of the final object fetcher to be sure we were uploading
  // chunks as expected
  GDataHTTPUploadFetcher *uploadFetcher = (GDataHTTPUploadFetcher *) [ticket_ objectFetcher];
  GDataHTTPFetcher *fetcher = [uploadFetcher activeFetcher];
  NSURLRequest *request = [fetcher request];
  NSDictionary *reqHdrs = [request allHTTPHeaderFields];

  NSString *uploadReqURLStr = @"http://localhost:54579/EntrySpreadsheetCellTest1.xml.upload";
  NSString *contentLength = [reqHdrs objectForKey:@"Content-Length"];
  NSString *contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertEqualObjects([[request URL] absoluteString], uploadReqURLStr,
                       @"upload request wrong");
  STAssertEqualObjects(contentLength, @"49000", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 150000-198999/199000", @"range");

  [self resetFetchResponse];

  //
  // repeat the previous upload, using NSData
  //
  [newEntry setUploadData:bigData];
  [newEntry setUploadFileHandle:nil];

  ticket_ = [service_ fetchEntryByInsertingEntry:newEntry
                                      forFeedURL:uploadURL
                                        delegate:self
                               didFinishSelector:@selector(ticket:finishedWithObject:error:)];
  [ticket_ retain];

  [self waitForFetch];

  STAssertNil(fetcherError_, @"fetcherError_=%@", fetcherError_);

  // check that we got back the expected entry
  entryID = @"http://spreadsheets.google.com/feeds/cells/o04181601172097104111.497668944883620000/od6/private/full/R1C1";
  STAssertEqualObjects([(GDataEntrySpreadsheetCell *)fetchedObject_ identifier],
                       entryID, @"uploading %@", uploadURL);

  // check the request of the final object fetcher to be sure we were uploading
  // chunks as expected
  uploadFetcher = (GDataHTTPUploadFetcher *) [ticket_ objectFetcher];
  fetcher = [uploadFetcher activeFetcher];
  request = [fetcher request];
  reqHdrs = [request allHTTPHeaderFields];

  uploadReqURLStr = @"http://localhost:54579/EntrySpreadsheetCellTest1.xml.upload";
  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertEqualObjects([[request URL] absoluteString], uploadReqURLStr,
                       @"upload request wrong");
  STAssertEqualObjects(contentLength, @"49000", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 150000-198999/199000", @"range");

  [self resetFetchResponse];

  //
  // repeat the first upload, pausing after 20000 bytes
  //

  ticket_ = [service_ fetchEntryByInsertingEntry:newEntry
                                      forFeedURL:uploadURL
                                        delegate:self
                               didFinishSelector:@selector(ticket:finishedWithObject:error:)];
  // add a property to the ticket that our progress callback will look for to
  // know when to pause and resume the upload
  [ticket_ setProperty:[NSNumber numberWithInt:20000]
                forKey:kPauseAtKey];
  [ticket_ retain];
  [self waitForFetch];

  STAssertEqualObjects([(GDataEntrySpreadsheetCell *)fetchedObject_ identifier],
                       entryID, @"uploading %@", uploadURL);

  uploadFetcher = (GDataHTTPUploadFetcher *) [ticket_ objectFetcher];
  fetcher = [uploadFetcher activeFetcher];
  request = [fetcher request];
  reqHdrs = [request allHTTPHeaderFields];

  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertEqualObjects([[request URL] absoluteString], uploadReqURLStr,
                       @"upload request wrong");
  STAssertEqualObjects(contentLength, @"24499", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 174501-198999/199000", @"range");

  [self resetFetchResponse];

  //
  // repeat the first upload, and after sending 70000 bytes the progress
  // callback will change the request URL for the next chunk fetch to make
  // it fail with a retryable status error
  //

  ticket_ = [service_ fetchEntryByInsertingEntry:newEntry
                                      forFeedURL:uploadURL
                                        delegate:self
                               didFinishSelector:@selector(ticket:finishedWithObject:error:)];
  // add a property to the ticket that our progress callback will use to
  // force a retry after 70000 bytes are uploaded
  [ticket_ setProperty:[NSNumber numberWithInt:70000]
                forKey:kRetryAtKey];
  [ticket_ retain];
  [self waitForFetch];

  STAssertEqualObjects([(GDataEntrySpreadsheetCell *)fetchedObject_ identifier],
                       entryID, @"uploading %@", uploadURL);

  uploadFetcher = (GDataHTTPUploadFetcher *) [ticket_ objectFetcher];
  fetcher = [uploadFetcher activeFetcher];
  request = [fetcher request];
  reqHdrs = [request allHTTPHeaderFields];

  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertEqualObjects([[request URL] absoluteString], uploadReqURLStr,
                       @"upload request wrong");
  STAssertEqualObjects(contentLength, @"24499", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 174501-198999/199000", @"range");

  [self resetFetchResponse];

  //
  // repeat the first upload, but uploading data only, without the entry XML
  //

  [newEntry setShouldUploadDataOnly:YES];
  [newEntry setUploadSlug:@"filename slug.txt"];

  ticket_ = [service_ fetchEntryByInsertingEntry:newEntry
                                      forFeedURL:uploadURL
                                        delegate:self
                               didFinishSelector:@selector(ticket:finishedWithObject:error:)];
  [ticket_ retain];

  [self waitForFetch];

  STAssertEqualObjects([(GDataEntrySpreadsheetCell *)fetchedObject_ identifier],
                       entryID, @"uploading %@", uploadURL);

  uploadFetcher = (GDataHTTPUploadFetcher *) [ticket_ objectFetcher];
  fetcher = [uploadFetcher activeFetcher];
  request = [fetcher request];
  reqHdrs = [request allHTTPHeaderFields];

  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertEqualObjects([[request URL] absoluteString], uploadReqURLStr,
                       @"upload request wrong");
  STAssertEqualObjects(contentLength, @"49000", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 150000-198999/199000", @"range");

  [self resetFetchResponse];

  //
  // upload a small data block
  //

  [newEntry setUploadData:smallData];
  [newEntry setShouldUploadDataOnly:NO];

  ticket_ = [service_ fetchEntryByInsertingEntry:newEntry
                                      forFeedURL:uploadURL
                                        delegate:self
                               didFinishSelector:@selector(ticket:finishedWithObject:error:)];
  [ticket_ retain];

  [self waitForFetch];

  STAssertNil(fetcherError_, @"fetcherError_=%@", fetcherError_);

  // check that we got back the expected entry
  STAssertEqualObjects([(GDataEntrySpreadsheetCell *)fetchedObject_ identifier],
                       entryID, @"uploading %@", uploadURL);

  // check the request of the final (and only) object fetcher to be sure we
  // were uploading chunks as expected
  uploadFetcher = (GDataHTTPUploadFetcher *) [ticket_ objectFetcher];
  fetcher = [uploadFetcher activeFetcher];
  request = [fetcher request];
  reqHdrs = [request allHTTPHeaderFields];

  contentLength = [reqHdrs objectForKey:@"Content-Length"];
  contentRange = [reqHdrs objectForKey:@"Content-Range"];

  STAssertEqualObjects([[request URL] absoluteString], uploadReqURLStr,
                       @"upload request wrong");
  STAssertEqualObjects(contentLength, @"13", @"content length");
  STAssertEqualObjects(contentRange, @"bytes 0-12/13", @"range");

  [self resetFetchResponse];

  [service_ setServiceUploadChunkSize:0];
  [service_ setServiceUploadProgressSelector:NULL];
  [service_ setServiceRetrySelector:NULL];

  [[NSFileManager defaultManager] removeItemAtPath:bigFilePath error:NULL];
   */
}
/*
- (void)uploadTicket:(GDataServiceTicket *)ticket
hasDeliveredByteCount:(unsigned long long)numberOfBytesRead
    ofTotalByteCount:(unsigned long long)dataLength {

  lastProgressDeliveredCount_ = numberOfBytesRead;
  lastProgressTotalCount_ = dataLength;

  NSNumber *pauseAtNum = [ticket propertyForKey:kPauseAtKey];
  if (pauseAtNum) {
    int pauseAt = [pauseAtNum intValue];
    if (pauseAt < numberOfBytesRead) {
      // we won't be paused again
      [ticket setProperty:nil forKey:kPauseAtKey];

      // we've reached the point where we should pause
      //
      // use perform selector to avoid pausing immediately, as that would nuke
      // the chunk upload fetcher that is calling us back now
      [ticket performSelector:@selector(pauseUpload) withObject:nil afterDelay:0.0];

      [ticket performSelector:@selector(resumeUpload) withObject:nil afterDelay:1.0];
    }
  }

  NSNumber *retryAtNum = [ticket propertyForKey:kRetryAtKey];
  if (retryAtNum) {
    int retryAt = [retryAtNum intValue];
    if (retryAt < numberOfBytesRead) {
      // we won't be retrying again
      [ticket setProperty:nil forKey:kRetryAtKey];

      // save the current locationURL  before appending &status=503
      GDataHTTPUploadFetcher *uploadFetcher = (GDataHTTPUploadFetcher *) [ticket objectFetcher];
      NSURL *origURL = [uploadFetcher locationURL];
      [ticket setProperty:origURL forKey:kOriginalURLKey];

      NSString *newURLStr = [[origURL absoluteString] stringByAppendingString:@"?status=503"];
      [uploadFetcher setLocationURL:[NSURL URLWithString:newURLStr]];
    }
  }
}

-(BOOL)uploadRetryTicket:(GDataServiceTicket *)ticket willRetry:(BOOL)suggestedWillRetry forError:(NSError *)error {

  // change this fetch's request (and future requests) to have the original URL,
  // not the one with status=503 appended
  NSURL *origURL = [ticket propertyForKey:kOriginalURLKey];
  GDataHTTPUploadFetcher *uploadFetcher = (GDataHTTPUploadFetcher *) [ticket objectFetcher];

  [[[uploadFetcher activeFetcher] request] setURL:origURL];
  [uploadFetcher setLocationURL:origURL];

  [ticket setProperty:nil forKey:kOriginalURLKey];

  return suggestedWillRetry; // do the retry fetch; it should succeed now
}
 */
@end

