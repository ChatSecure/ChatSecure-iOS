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

//
//  GTMReadMonitorInputStreamTest.m
//

#import <SenTestingKit/SenTestingKit.h>

#import "GTMReadMonitorInputStream.h"

@interface GTMReadMonitorInputStreamTest : SenTestCase {
  NSMutableData *monitoredData_;
}
@end

@implementation GTMReadMonitorInputStreamTest

- (void)setUp {
  monitoredData_ = [[NSMutableData alloc] init];
}

- (void)tearDown {
  [monitoredData_ release];
  monitoredData_ = nil;
}

- (void)testGTMReadMonitorInputStream {

  // Make some data with lotsa bytes
  NSMutableData *testData = [NSMutableData data];
  for (int idx = 0; idx < 100; idx++) {
    const char *str = "abcdefghijklmnopqrstuvwxyz ";
    [testData appendBytes:str length:strlen(str)];
  }

  // Make a stream for the data
  NSInputStream *dataStream = [NSInputStream inputStreamWithData:testData];

  // Make a monitor stream, with self as the delegate
  GTMReadMonitorInputStream *monitorStream;
  monitorStream = [GTMReadMonitorInputStream inputStreamWithStream:dataStream];
  SEL sel = @selector(inputStream:readIntoBuffer:length:);

  monitorStream.readDelegate = self;
  monitorStream.readSelector = sel;

  // Now read random size chunks of data and append them to a mutable NSData
  NSMutableData *readData = [NSMutableData data];

  [monitorStream open];
  while ([monitorStream hasBytesAvailable]) {

    unsigned char buffer[101];
    NSUInteger numBytesToRead = (arc4random() % 100) + 1;

    NSInteger numRead = [monitorStream read:buffer maxLength:numBytesToRead];
    if (numRead == 0) break;

    // Append the read chunk to our buffer
    [readData appendBytes:buffer length:numRead];
  }
  [monitorStream close];

  // Verify we read all the data
  STAssertEqualObjects(readData, testData,
                       @"read data doesn't match stream data");

  // Verify the callback saw the same data
  STAssertEqualObjects(monitoredData_, testData,
                       @"callback progress doesn't match actual progress");
}


- (void)inputStream:(GTMReadMonitorInputStream *)stream
     readIntoBuffer:(uint8_t *)buffer
             length:(NSUInteger)length {
  [monitoredData_ appendBytes:buffer
                       length:length];
}
@end
