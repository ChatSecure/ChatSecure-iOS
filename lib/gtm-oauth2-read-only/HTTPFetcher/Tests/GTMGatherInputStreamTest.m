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

#import "GTMGatherInputStream.h"

@interface GTMGatherInputStreamTest : SenTestCase
@end

@implementation GTMGatherInputStreamTest

- (void)doReadTestForInputStream:(NSInputStream *)inputStream
                  expectedString:(NSString *)expectedResultString
                 usingSmallReads:(BOOL)useSmallReads
                      testMethod:(SEL)callingMethod {
  // this routine, called by the later test methods,
  // reads the data from the input stream and verifies that it matches
  // the expected string
  NSString *testMethod = NSStringFromSelector(callingMethod);

  // now read the document from the input stream
  unsigned char buffer[9999];
  memset(buffer, 0, sizeof(buffer));

  [inputStream open];

  NSInteger bytesRead = 0;

  if (!useSmallReads) {
    // big read
    bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
  } else {
    // small 1-byte reads
    NSInteger bytesReadNow;
    do {
      bytesReadNow = [inputStream read:(buffer + bytesRead) maxLength:1];
      bytesRead += bytesReadNow;
    } while (bytesReadNow > 0);
  }

  [inputStream close];

  NSString *readString = [NSString stringWithUTF8String:(const char * )buffer];

  STAssertEqualObjects(readString, expectedResultString, @"bad read (%@)",
                       testMethod);

  NSInteger expectedLength = [expectedResultString length];
  STAssertEquals(bytesRead, expectedLength, @"bad read length (%@)",
                 testMethod);
}


// Make sure that an empty array of data buffers works ok.
- (void)testEmptyGatherStream {
  NSArray* array = [NSArray array];
  NSInputStream* input = [GTMGatherInputStream streamWithArray:array];

  [self doReadTestForInputStream:input
                  expectedString:@""
                 usingSmallReads:NO
                      testMethod:_cmd];
}


- (void)testGatherStreamWithEmptyParts {
  char buf[] = "hello";
  NSString *expectedString = @"hello";

  NSMutableArray* array = [NSMutableArray array];

  [array addObject:[NSData dataWithBytes:"" length:0]];
  [array addObject:[NSData dataWithBytes:buf length:strlen(buf)]];
  [array addObject:[NSData dataWithBytes:"" length:0]];

  NSInputStream* input = [GTMGatherInputStream streamWithArray:array];

  [self doReadTestForInputStream:input
                  expectedString:expectedString
                 usingSmallReads:NO
                      testMethod:_cmd];
}

// We read all of the data in one big chunk.
- (void)testGatherStreamWithManyBuffers {
  char b1[] = "h";
  char b2[] = "ello";
  char b3[] = "";
  char b4[] = " how are you?";
  NSString *expectedString = @"hello how are you?";

  NSMutableArray* array = [NSMutableArray array];
  [array addObject:[NSData dataWithBytes:b1 length:strlen(b1)]];
  [array addObject:[NSData dataWithBytes:b2 length:strlen(b2)]];
  [array addObject:[NSData dataWithBytes:b3 length:strlen(b3)]];
  [array addObject:[NSData dataWithBytes:b4 length:strlen(b4)]];

  NSInputStream* input = [GTMGatherInputStream streamWithArray:array];

  [self doReadTestForInputStream:input
                  expectedString:expectedString
                 usingSmallReads:NO
                      testMethod:_cmd];
}


// We read one byte at a time to make sure that many calls to read work properly.
- (void)testGatherStreamWithManyCalls {
  char b1[] = "h";
  char b2[] = "ello";
  char b3[] = "";
  char b4[] = " how are you?";
  NSString *expectedString = @"hello how are you?";

  NSMutableArray* array = [NSMutableArray array];
  [array addObject:[NSData dataWithBytes:b1 length:strlen(b1)]];
  [array addObject:[NSData dataWithBytes:b2 length:strlen(b2)]];
  [array addObject:[NSData dataWithBytes:b3 length:strlen(b3)]];
  [array addObject:[NSData dataWithBytes:b4 length:strlen(b4)]];

  NSInputStream* input = [GTMGatherInputStream streamWithArray:array];

  [self doReadTestForInputStream:input
                  expectedString:expectedString
                 usingSmallReads:YES
                      testMethod:_cmd];
}

@end
