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

#import <SenTestingKit/SenTestingKit.h>

#import "GTMMIMEDocument.h"

// /Developer/Tools/otest LighthouseAPITest.octest

@interface GTMMIMEDocumentTest : SenTestCase
@end

@implementation GTMMIMEDocumentTest

- (void)doReadTestForInputStream:(NSInputStream *)inputStream
                  expectedString:(NSString *)expectedResultString
                      testMethod:(SEL)callingMethod {
  // this routine, called by the later test methods,
  // reads the data from the input stream and verifies that it matches
  // the expected string

  NSInteger expectedLength = [expectedResultString length];

  // now read the document from the input stream
  unsigned char buffer[9999];
  memset(buffer, 0, sizeof(buffer));

  [inputStream open];
  NSInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
  [inputStream close];

  NSString *readString = [NSString stringWithUTF8String:(const char * )buffer];

  STAssertEqualObjects(readString, expectedResultString, @"bad read (%@)",
                       NSStringFromSelector(callingMethod));

  STAssertEquals(bytesRead, expectedLength, @"bad read length (%@)",
                 NSStringFromSelector(callingMethod));
}


- (void)testEmptyDoc {

  GTMMIMEDocument* doc = [GTMMIMEDocument MIMEDocument];

  NSInputStream *stream = nil;
  NSString *boundary = nil;
  unsigned long long length = -1;

  // generate the boundary and the input stream
  [doc generateInputStream:&stream
                    length:&length
                  boundary:&boundary];

  STAssertEqualObjects(boundary, @"END_OF_PART", @"bad boundary");

  NSString *expectedString = @"\r\n--END_OF_PART--\r\n";
  NSUInteger expectedLength = [expectedString length];

  STAssertEquals((NSUInteger)length, expectedLength,
                 @"Reported document length should be expected length.");

  [self doReadTestForInputStream:stream
                  expectedString:expectedString
                      testMethod:_cmd];
}

- (void)testSinglePartDoc {

  GTMMIMEDocument* doc = [GTMMIMEDocument MIMEDocument];

  NSDictionary* h1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"bar", @"hfoo",
                             @"baz", @"hfaz",
                             nil];
  NSData* b1 = [@"Hi mom" dataUsingEncoding:NSUTF8StringEncoding];
  [doc addPartWithHeaders:h1 body:b1];

  // generate the boundary and the input stream
  NSInputStream *stream = nil;
  NSString *boundary = nil;
  unsigned long long length = -1;

  [doc generateInputStream:&stream
                    length:&length
                  boundary:&boundary];

  NSString* expectedResultString = [NSString stringWithFormat:
                                    @"\r\n--%@\r\n"
                                    "hfaz: baz\r\n"
                                    "hfoo: bar\r\n"
                                    "\r\n"    // Newline after headers.
                                    "Hi mom"
                                    "\r\n--%@--\r\n", boundary, boundary];

  STAssertEqualObjects(boundary, @"END_OF_PART", @"bad boundary");

  NSUInteger expectedLength = [expectedResultString length];

  STAssertEquals((NSUInteger)length, expectedLength,
                 @"Reported document length should be expected length.");

  // now read the document from the input stream

  [self doReadTestForInputStream:stream
                  expectedString:expectedResultString
                      testMethod:_cmd];

}


- (void)testMultiPartDoc {
  GTMMIMEDocument* doc = [GTMMIMEDocument MIMEDocument];

  NSDictionary* h1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"bar", @"hfoo",
                             @"baz", @"hfaz",
                             nil];
  NSData* b1 = [@"Hi mom" dataUsingEncoding:NSUTF8StringEncoding];

  NSDictionary* h2 = [NSDictionary dictionary];
  NSData* b2 = [@"Hi dad" dataUsingEncoding:NSUTF8StringEncoding];

  NSDictionary* h3 = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"text/html", @"Content-Type",
                      @"angry", @"Content-Disposition",
                      nil];
  NSData* b3 = [@"Hi brother" dataUsingEncoding:NSUTF8StringEncoding];

  [doc addPartWithHeaders:h1 body:b1];
  [doc addPartWithHeaders:h2 body:b2];
  [doc addPartWithHeaders:h3 body:b3];

  // generate the boundary and the input stream
  NSInputStream *stream = nil;
  NSString *boundary = nil;
  unsigned long long length = -1;

  [doc generateInputStream:&stream
                    length:&length
                  boundary:&boundary];

  NSString* expectedResultString = [NSString stringWithFormat:
    @"\r\n--%@\r\n"
    "hfaz: baz\r\n"
    "hfoo: bar\r\n"
    "\r\n"    // Newline after headers.
    "Hi mom"
    "\r\n--%@\r\n"
    "\r\n"    // No header here, but still need the newline.
    "Hi dad"
    "\r\n--%@\r\n"
    "Content-Disposition: angry\r\n"
    "Content-Type: text/html\r\n"
    "\r\n"    // Newline after headers.
    "Hi brother"
    "\r\n--%@--\r\n",
    boundary, boundary, boundary, boundary];

  // now read the document from the input stream
  [self doReadTestForInputStream:stream
                  expectedString:expectedResultString
                      testMethod:_cmd];
}

- (void)testBoundaryConflict {
  GTMMIMEDocument* doc = [GTMMIMEDocument MIMEDocument];

  // we'll insert the text END_OF_PART_6b8b4567 which conflicts with
  // both the normal boundary ("END_OF_PART") and the first alternate
  // guess (given a random seed of 1, done below)

  NSDictionary* h1 = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"bar", @"hfoo",
                             @"baz", @"hfaz",
                             nil];
  NSData* b1 = [@"Hi mom END_OF_PART" dataUsingEncoding:NSUTF8StringEncoding];

  NSDictionary* h2 = [NSDictionary dictionary];
  NSData* b2 = [@"Hi dad" dataUsingEncoding:NSUTF8StringEncoding];

  NSDictionary* h3 = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"text/html", @"Content-Type",
                      @"angry", @"Content-Disposition",
                      nil];
  NSData* b3 = [@"Hi brother END_OF_PART_6b8b4567" dataUsingEncoding:NSUTF8StringEncoding];

  [doc addPartWithHeaders:h1 body:b1];
  [doc addPartWithHeaders:h2 body:b2];
  [doc addPartWithHeaders:h3 body:b3];

  // generate the boundary and the input stream
  NSInputStream *stream = nil;
  NSString *boundary = nil;
  unsigned long long length = -1;

  [doc seedRandomWith:1];
  [doc generateInputStream:&stream
                    length:&length
                  boundary:&boundary];

  // the second alternate boundary, given the random seed
  boundary = @"END_OF_PART_00000001";

  NSString* expectedResultString = [NSString stringWithFormat:
    @"\r\n--%@\r\n"
    "hfaz: baz\r\n"
    "hfoo: bar\r\n"
    "\r\n"    // Newline after headers.
    "Hi mom END_OF_PART"  // intentional conflict
    "\r\n--%@\r\n"
    "\r\n"    // No header here, but still need the newline.
    "Hi dad"
    "\r\n--%@\r\n"
    "Content-Disposition: angry\r\n"
    "Content-Type: text/html\r\n"
    "\r\n"    // Newline after headers.
    "Hi brother END_OF_PART_6b8b4567" // conflict with the first guess
    "\r\n--%@--\r\n",
    boundary, boundary, boundary, boundary];

  // now read the document from the input stream
  [self doReadTestForInputStream:stream
                  expectedString:expectedResultString
                      testMethod:_cmd];
}

@end
