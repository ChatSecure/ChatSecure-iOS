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

#import "GTMReadMonitorInputStream.h"

@interface GTMReadMonitorInputStream ()
- (void)invokeReadSelectorWithBuffer:(NSData *)data;
@end

@implementation GTMReadMonitorInputStream

@synthesize readDelegate = readDelegate_;
@synthesize readSelector = readSelector_;
@synthesize runLoopModes = runLoopModes_;

// We'll forward all unhandled messages to the NSInputStream class
// or to the encapsulated input stream.  This is needed
// for all messages sent to NSInputStream which aren't
// handled by our superclass; that includes various private run
// loop calls.
+ (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
  return [NSInputStream methodSignatureForSelector:selector];
}

+ (void)forwardInvocation:(NSInvocation*)invocation {
  [invocation invokeWithTarget:[NSInputStream class]];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
  return [inputStream_ methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation*)invocation {
  [invocation invokeWithTarget:inputStream_];
}

#pragma mark -

+ (id)inputStreamWithStream:(NSInputStream *)input {
  return [[[self alloc] initWithStream:input] autorelease];
}

- (id)initWithStream:(NSInputStream *)input  {
  self = [super init];
  if (self) {
    inputStream_ = [input retain];
    thread_ = [[NSThread currentThread] retain];
  }
  return self;
}

- (id)init {
  return [self initWithStream:nil];
}

- (void)dealloc {
  [inputStream_ release];
  [thread_ release];
  [runLoopModes_ release];
  [super dealloc];
}

#pragma mark -

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
  // Read from the encapsulated stream
  NSInteger numRead = [inputStream_ read:buffer maxLength:len];
  if (numRead > 0) {

    BOOL isOnOriginalThread = [thread_ isEqual:[NSThread currentThread]];

    if (readDelegate_ && readSelector_) {
      // call the read selector with the buffer and number of bytes actually
      // read into it
      SEL sel = @selector(invokeReadSelectorWithBuffer:);

      if (isOnOriginalThread) {
        // invoke immediately
        NSData *data = [NSData dataWithBytesNoCopy:buffer
                                            length:(NSUInteger)numRead
                                      freeWhenDone:NO];
        [self performSelector:sel withObject:data];
      } else {
        // copy the buffer into an NSData to be retained by the
        // performSelector, and invoke on the proper thread
        NSData *data = [NSData dataWithBytes:buffer length:(NSUInteger)numRead];
        if (runLoopModes_) {
          [self performSelector:sel
                       onThread:thread_
                     withObject:data
                  waitUntilDone:NO
                          modes:runLoopModes_];
        } else {
          [self performSelector:sel
                       onThread:thread_
                     withObject:data
                  waitUntilDone:NO];
        }
      }
    }
  }

  return numRead;
}

- (void)invokeReadSelectorWithBuffer:(NSData *)data {
  const void *buffer = [data bytes];
  NSUInteger length = [data length];

  NSMethodSignature *signature = [readDelegate_ methodSignatureForSelector:readSelector_];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setSelector:readSelector_];
  [invocation setTarget:readDelegate_];
  [invocation setArgument:&self atIndex:2];
  [invocation setArgument:&buffer atIndex:3];
  [invocation setArgument:&length atIndex:4];
  [invocation invoke];
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
  return [inputStream_ getBuffer:buffer length:len];
}

- (BOOL)hasBytesAvailable {
  return [inputStream_ hasBytesAvailable];
}

#pragma mark Standard messages

// Pass expected messages to our encapsulated stream.
//
// We want our encapsulated NSInputStream to handle the standard messages;
// we don't want the superclass to handle them.
- (void)open {
  [inputStream_ open];
}

- (void)close {
  [inputStream_ close];
}

- (id)delegate {
  return [inputStream_ delegate];
}

- (void)setDelegate:(id)delegate {
  [inputStream_ setDelegate:delegate];
}

- (id)propertyForKey:(NSString *)key {
  return [inputStream_ propertyForKey:key];
}
- (BOOL)setProperty:(id)property forKey:(NSString *)key {
  return [inputStream_ setProperty:property forKey:key];
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
  [inputStream_ scheduleInRunLoop:aRunLoop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
  [inputStream_ removeFromRunLoop:aRunLoop forMode:mode];
}

- (NSStreamStatus)streamStatus {
  return [inputStream_ streamStatus];
}

- (NSError *)streamError {
  return [inputStream_ streamError];
}

@end
