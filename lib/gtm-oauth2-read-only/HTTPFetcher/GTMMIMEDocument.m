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


#import "GTMMIMEDocument.h"
#import "GTMGatherInputStream.h"

// memsrch
//
// Helper routine to search for the existence of a set of bytes (needle) within
// a presumed larger set of bytes (haystack).
//
static BOOL memsrch(const unsigned char* needle, NSUInteger needle_len,
                    const unsigned char* haystack, NSUInteger haystack_len);

@interface GTMMIMEPart : NSObject {
  NSData* headerData_;  // Header content including the ending "\r\n".
  NSData* bodyData_;    // The body data.
}

+ (GTMMIMEPart *)partWithHeaders:(NSDictionary *)headers body:(NSData *)body;
- (id)initWithHeaders:(NSDictionary *)headers body:(NSData *)body;
- (BOOL)containsBytes:(const unsigned char *)bytes length:(NSUInteger)length;
- (NSData *)header;
- (NSData *)body;
- (NSUInteger)length;
@end

@implementation GTMMIMEPart

+ (GTMMIMEPart *)partWithHeaders:(NSDictionary *)headers body:(NSData *)body {

  return [[[self alloc] initWithHeaders:headers
                                   body:body] autorelease];
}

- (id)initWithHeaders:(NSDictionary *)headers
                 body:(NSData *)body {

  if ((self = [super init]) != nil) {

    bodyData_ = [body retain];

    // generate the header data by coalescing the dictionary as
    // lines of "key: value\r\m"
    NSMutableString* headerString = [NSMutableString string];

    // sort the header keys so we have a deterministic order for
    // unit testing
    SEL sortSel = @selector(caseInsensitiveCompare:);
    NSArray *sortedKeys = [[headers allKeys] sortedArrayUsingSelector:sortSel];

    for (NSString *key in sortedKeys) {
      NSString* value = [headers objectForKey:key];

#if DEBUG
      // look for troublesome characters in the header keys & values
      static NSCharacterSet *badChars = nil;
      if (!badChars) {
        badChars = [[NSCharacterSet characterSetWithCharactersInString:@":\r\n"] retain];
      }

      NSRange badRange = [key rangeOfCharacterFromSet:badChars];
      NSAssert1(badRange.location == NSNotFound, @"invalid key: %@", key);

      badRange = [value rangeOfCharacterFromSet:badChars];
      NSAssert1(badRange.location == NSNotFound, @"invalid value: %@", value);
#endif

      [headerString appendFormat:@"%@: %@\r\n", key, value];
    }

    // headers end with an extra blank line
    [headerString appendString:@"\r\n"];

    headerData_ = [[headerString dataUsingEncoding:NSUTF8StringEncoding] retain];
  }
  return self;
}

- (void) dealloc {
  [headerData_ release];
  [bodyData_ release];
  [super dealloc];
}

// Returns true if the parts contents contain the given set of bytes.
//
// NOTE: We assume that the 'bytes' we are checking for do not contain "\r\n",
// so we don't need to check the concatenation of the header and body bytes.
- (BOOL)containsBytes:(const unsigned char*)bytes length:(NSUInteger)length {

  // This uses custom memsrch() rather than strcpy because the encoded data may
  // contain null values.
  return memsrch(bytes, length, [headerData_ bytes], [headerData_ length]) ||
         memsrch(bytes, length, [bodyData_ bytes],   [bodyData_ length]);
}

- (NSData *)header {
  return headerData_;
}

- (NSData *)body {
  return bodyData_;
}

- (NSUInteger)length {
  return [headerData_ length] + [bodyData_ length];
}
@end

@implementation GTMMIMEDocument

+ (GTMMIMEDocument *)MIMEDocument {
  return [[[self alloc] init] autorelease];
}

- (id)init {
  if ((self = [super init]) != nil) {

    parts_ = [[NSMutableArray alloc] init];

    // Seed the random number generator used to generate mime boundaries
    srandomdev();
  }
  return self;
}

- (void)dealloc {
  [parts_ release];
  [super dealloc];
}

// Adds a new part to this mime document with the given headers and body.
- (void)addPartWithHeaders:(NSDictionary *)headers
                      body:(NSData *)body {

  GTMMIMEPart* part = [GTMMIMEPart partWithHeaders:headers body:body];
  [parts_ addObject:part];
}

// For unit testing only, seeds the random number generator so that we will
// have reproducible boundary strings.
- (void)seedRandomWith:(u_int32_t)seed {
  randomSeed_ = seed;
}

- (u_int32_t)random {
  if (randomSeed_) {
    // for testing only
    return randomSeed_++;
  } else {
    return arc4random();
  }
}

// Computes the mime boundary to use.  This should only be called
// after all the desired document parts have been added since it must compute
// a boundary that does not exist in the document data.
- (NSString *)uniqueBoundary {

  // use an easily-readable boundary string
  NSString *const kBaseBoundary = @"END_OF_PART";

  NSString *boundary = kBaseBoundary;

  // if the boundary isn't unique, append random numbers, up to 10 attempts;
  // if that's still not unique, use a random number sequence instead,
  // and call it good
  BOOL didCollide = NO;

  const int maxTries = 10;  // Arbitrarily chosen maximum attempts.
  for (int tries = 0; tries < maxTries; ++tries) {

    NSData *data = [boundary dataUsingEncoding:NSUTF8StringEncoding];
    const void *dataBytes = [data bytes];
    NSUInteger dataLen = [data length];

    for (GTMMIMEPart *part in parts_) {
      didCollide = [part containsBytes:dataBytes length:dataLen];
      if (didCollide) break;
    }

    if (!didCollide) break; // we're fine, no more attempts needed

    // try again with a random number appended
    boundary = [NSString stringWithFormat:@"%@_%08x", kBaseBoundary,
                [self random]];
  }

  if (didCollide) {
    // fallback... two random numbers
    boundary = [NSString stringWithFormat:@"%08x_tedborg_%08x",
                                          [self random], [self random]];
  }

  return boundary;
}

- (void)generateInputStream:(NSInputStream **)outStream
                     length:(unsigned long long*)outLength
                   boundary:(NSString **)outBoundary {

  // The input stream is of the form:
  //   --boundary
  //    [part_1_headers]
  //    [part_1_data]
  //   --boundary
  //    [part_2_headers]
  //    [part_2_data]
  //   --boundary--

  // First we set up our boundary NSData objects.
  NSString *boundary = [self uniqueBoundary];

  NSString *mainBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
  NSString *endBoundary = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];

  NSData *mainBoundaryData = [mainBoundary dataUsingEncoding:NSUTF8StringEncoding];
  NSData *endBoundaryData = [endBoundary dataUsingEncoding:NSUTF8StringEncoding];

  // Now we add them all in proper order to our dataArray.
  NSMutableArray* dataArray = [NSMutableArray array];
  unsigned long long length = 0;

  for (GTMMIMEPart* part in parts_) {
    [dataArray addObject:mainBoundaryData];
    [dataArray addObject:[part header]];
    [dataArray addObject:[part body]];

    length += [part length] + [mainBoundaryData length];
  }

  [dataArray addObject:endBoundaryData];
  length += [endBoundaryData length];

  if (outLength)   *outLength = length;
  if (outStream)   *outStream = [GTMGatherInputStream streamWithArray:dataArray];
  if (outBoundary) *outBoundary = boundary;
}

@end


// memsrch - Return YES if needle is found in haystack, else NO.
static BOOL memsrch(const unsigned char* needle, NSUInteger needleLen,
                    const unsigned char* haystack, NSUInteger haystackLen) {

  // This is a simple approach.  We start off by assuming that both memchr() and
  // memcmp are implemented efficiently on the given platform.  We search for an
  // instance of the first char of our needle in the haystack.  If the remaining
  // size could fit our needle, then we memcmp to see if it occurs at this point
  // in the haystack.  If not, we move on to search for the first char again,
  // starting from the next character in the haystack.
  const unsigned char* ptr = haystack;
  NSUInteger remain = haystackLen;
  while ((ptr = memchr(ptr, needle[0], remain)) != 0) {
    remain = haystackLen - (NSUInteger)(ptr - haystack);
    if (remain < needleLen) {
      return NO;
    }
    if (memcmp(ptr, needle, needleLen) == 0) {
      return YES;
    }
    ptr++;
    remain--;
  }
  return NO;
}
