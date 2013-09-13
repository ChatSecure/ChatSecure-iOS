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

#import <Foundation/Foundation.h>


// Define <NSStreamDelegate> only for Mac OS X 10.6+ or iPhone OS 4.0+.
#ifndef GTM_NSSTREAM_DELEGATE
 #if (TARGET_OS_MAC && !TARGET_OS_IPHONE && (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)) || \
     (TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 40000))
   #define GTM_NSSTREAM_DELEGATE <NSStreamDelegate>
 #else
   #define GTM_NSSTREAM_DELEGATE
 #endif
#endif  // !defined(GTM_NSSTREAM_DELEGATE)

#ifdef GTM_TARGET_NAMESPACE
  // we're using target namespace macros
  #import "GTMDefines.h"
#endif

@interface GTMReadMonitorInputStream : NSInputStream GTM_NSSTREAM_DELEGATE {
 @protected
  NSInputStream *inputStream_; // encapsulated stream that does the work

  NSThread *thread_;      // thread in which this object was created
  NSArray *runLoopModes_; // modes for calling callbacks, when necessary

 @private
  id readDelegate_;
  SEL readSelector_;
}

// length is passed to the progress callback; it may be zero
// if the progress callback can handle that
+ (id)inputStreamWithStream:(NSInputStream *)input;

- (id)initWithStream:(NSInputStream *)input;

// The read monitor selector is called when bytes have been read. It should
// have a signature matching
//
// - (void)inputStream:(GTMReadMonitorInputStream *)stream
//      readIntoBuffer:(uint8_t *)buffer
//              length:(NSUInteger)length;

@property (assign) id readDelegate; // WEAK
@property (assign) SEL readSelector;

// Modes for invoking callbacks, when necessary
@property (retain) NSArray *runLoopModes;

@end
