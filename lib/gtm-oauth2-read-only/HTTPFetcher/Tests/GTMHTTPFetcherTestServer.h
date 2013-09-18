//
//  GTMHTTPFetcherTestServer.h
//
//  Copyright 2010 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "GTMHTTPServer.h"


// This is a HTTP Server that responsd to requests by returning the requested
// file.  It takes extra url arguments to tell it what to
// return for testing the code using it.
@interface GTMHTTPFetcherTestServer : NSObject {
  NSString *docRoot_;
  GTMHTTPServer *server_;
}

// Any url that isn't a specific server request (login, etc.), will be fetched
// off |docRoot| (to allow canned repsonses).
- (id)initWithDocRoot:(NSString *)docRoot;

- (void)stopServer;

// fetch the port the server is running on
- (uint16_t)port;

// utilities for users
- (NSURL *)localURLForFile:(NSString *)name;     // http://localhost:port/filename
- (NSString *)localPathForFile:(NSString *)name; // docRoot/filename
@end
